# Public API and types

## Purpose

Define the stable Julia-facing vocabulary before formulas are implemented. Avoid copying R naming and return-container conventions.

## Public API names

Export these names when implemented:

```julia
solar_zenith
relative_humidity_from_dewpoint
vapour_pressure
wet_bulb_temperature_stull
wbgt_bernard
simplified_wbgt
apparent_temperature
effective_temperature
humidex
discomfort_index
heat_index
globe_temperature
natural_wet_bulb_temperature
liljegren_wbgt
liljegren_wbgt_batch
liljegren_wbgt!
diagnose_liljegren
diagnose_liljegren_batch
```

Do not export R aliases such as `wbgt.Liljegren`, `fTg`, `fTnwb`, `wbt.Stull`, `apparentTemp` or `tashurs2vap.pres` in v0.1.0. A separate compatibility extension may be considered later.

Do not implement `indexShow()`. Replace it with ordinary Julia docstrings and `docs/src/api.md`.

## Public scalar signatures

Canonical value-only call:

```julia
liljegren_wbgt(
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    solar_radiation_w_m2,
    time,
    longitude_deg,
    latitude_deg;
    pressure_hpa = 1010,
    direct_fraction = 0.8,
    config = LiljegrenConfig(),
)
```

Canonical diagnostic call:

```julia
diagnose_liljegren(
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    solar_radiation_w_m2,
    time,
    longitude_deg,
    latitude_deg;
    pressure_hpa = 1010,
    direct_fraction = 0.8,
    config = LiljegrenConfig(),
)
```

`liljegren_wbgt` returns `WBGTResult`; `diagnose_liljegren` returns `DiagnosticWBGTResult`. Do not use a `diagnostics=true` keyword that changes return shape.

## Time inputs

Support:

- `ZonedDateTime`: convert the instant to UTC before solar calculations;
- `DateTime`: interpret explicitly as UTC and document this;
- `Date`: valid primarily for `DateNoon`; in timestamp mode interpret as midnight UTC only if explicitly documented and tested;
- `Missing`: propagate as an unattempted/missing-time result at the public boundary.

Do not parse arbitrary strings in hot APIs. Provide an optional convenience method only after core completion, or require callers to parse with `TimeZones.jl`/`Dates`.

## Policy enums

Use explicit enums or singleton values, not paired Booleans.

```julia
@enum DewPointPolicy::UInt8 begin
    ClampDewPoint
    SwapAirAndDewPoint
    RejectInvalidDewPoint
end

@enum SolarTimeMode::UInt8 begin
    TimestampSolarTime
    DateNoonSolarTime
end

@enum InputStatus::UInt8 begin
    InputAccepted
    MissingMeteorology
    MissingTime
    InvalidDewPoint
    InvalidDomain
end

@enum FailureReason::UInt8 begin
    NoFailure
    NotAttempted
    Unbracketed
    NonFiniteResidual
    ResidualValidationFailed
    IterationLimit
end
```

Names may be adjusted once for clarity before public release, but meanings must not change silently.

Policy design:

| Situation | Julia policy |
| --- | --- |
| dewpoint exceeds air temperature within/above tolerance; clamp to saturation | `ClampDewPoint` (provisional default) |
| dewpoint exceeds air temperature; exchange the two values for legacy-data repair | `SwapAirAndDewPoint` |
| dewpoint exceeds air temperature; reject row | `RejectInvalidDewPoint` |
| compute solar geometry from full instant | `TimestampSolarTime` |
| compute a documented date-at-noon approximation | `DateNoonSolarTime` |

The default dewpoint policy must be justified in documentation; it is a package decision, not inherited behaviour.

## Configuration types

```julia
struct SolverConfig{T<:AbstractFloat}
    root_tolerance_k::T
    residual_tolerance_k::T
    maximum_iterations::Int
end

struct LiljegrenConfig{T<:AbstractFloat}
    solver::SolverConfig{T}
    dew_point_policy::DewPointPolicy
    dew_point_tolerance_c::T
    solar_time_mode::SolarTimeMode
    surface_albedo::T
    globe_diameter_m::T
    minimum_wind_speed_m_s::T
end
```

Provide validating outer constructors. Defaults:

```julia
SolverConfig(
    root_tolerance_k = 1e-6,
    residual_tolerance_k = 1e-4,
    maximum_iterations = 128,
)

LiljegrenConfig(
    solver = SolverConfig(),
    dew_point_policy = ClampDewPoint,
    dew_point_tolerance_c = 1e-4,
    solar_time_mode = TimestampSolarTime,
    surface_albedo = 0.45,
    globe_diameter_m = 0.0508,
    minimum_wind_speed_m_s = 0.13,
)
```

Do not expose an umbrella `tolerance` parameter. Document each numerical tolerance independently.

## Result types

```julia
struct WBGTResult{T<:AbstractFloat}
    wbgt_c::Union{Missing,T}
    natural_wet_bulb_c::Union{Missing,T}
    globe_temperature_c::Union{Missing,T}
end

struct SolverDiagnostics{T<:AbstractFloat}
    converged::Bool
    reason::FailureReason
    value_c::Union{Missing,T}
    candidate_c::Union{Missing,T}
    residual_k::Union{Missing,T}
    evaluations::Int
    iterations::Int
    initial_lower_k::Union{Missing,T}
    initial_upper_k::Union{Missing,T}
    final_lower_k::Union{Missing,T}
    final_upper_k::Union{Missing,T}
    lower_residual::Union{Missing,T}
    upper_residual::Union{Missing,T}
    root_tolerance_k::T
    residual_tolerance_k::T
end

struct DiagnosticWBGTResult{T<:AbstractFloat}
    result::WBGTResult{T}
    input_status::InputStatus
    solar_geometry_mismatch::Bool
    globe::SolverDiagnostics{T}
    natural_wet_bulb::SolverDiagnostics{T}
end
```

For batch results use structure-of-arrays types, not `Vector{DiagnosticWBGTResult}` in the main high-throughput path:

```julia
struct WBGTBatchResult{T,V<:AbstractVector{Union{Missing,T}}}
    wbgt_c::V
    natural_wet_bulb_c::V
    globe_temperature_c::V
end
```

The diagnostic batch type may contain vectors for each diagnostic field. It must preserve row alignment.

## Missing and failure semantics

- Missing/invalid public input: result components are `missing`; solver reason is `NotAttempted`.
- Failed Tg only: `globe_temperature_c=missing`, retain valid natural wet bulb, `wbgt_c=missing`.
- Failed Tnwb only: retain valid globe temperature, natural wet bulb and WBGT are missing.
- Complete WBGT is calculated only if both component roots validate.
- A solver candidate that fails residual validation must not be returned as the component value; retain it only in diagnostics.

## Numeric type policy

- Accept `Real` scalar inputs.
- Promote all numeric inputs and config values to a common floating type at the public boundary.
- Kernels should primarily operate on `T<:AbstractFloat`.
- Preserve `Float32` where practical; do not unconditionally convert every call to `Float64` unless a documented numerical limitation requires it.
- Tests must cover `Float32` and `Float64` for finite ordinary cases.
- BigFloat support is desirable but not a v0.1 acceptance requirement.

## Acceptance criteria

- Constructors reject nonsensical tolerance, albedo, diameter and wind-floor values.
- Result types are concrete and inferable.
- `@inferred` passes for ordinary Float64 scalar construction and public calls once implemented.
- software-specific legacy names and paired Boolean policy arguments do not appear in the exported API.

## Suggested commit

`feat: define native Julia API and result types`

