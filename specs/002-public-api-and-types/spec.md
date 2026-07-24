# Public API and types

## Purpose

Define the stable Julia-facing vocabulary before formulas are implemented. Avoid copying R naming and return-container conventions.

## Public API names

The Liljegren, solver and batch names below are the stable v0.1 candidates. Solar/psychrometric names are finalised by 004; secondary-index names are finalised by 009 after each exact formulation is selected. Export a name only when its owning specification is complete.

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

The generic secondary-index names above are not commitments to unspecified formula variants. Spec 009 must either bind each name to one cited formulation or replace it with a formulation-specific name before implementation.

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
    direct_fraction,
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
    direct_fraction,
    config = LiljegrenConfig(),
)
```

`liljegren_wbgt` returns `WBGTResult`; `diagnose_liljegren` returns `DiagnosticWBGTResult`. Do not use a `diagnostics=true` keyword that changes return shape.

`direct_fraction` is required until a separately sourced direct/diffuse
radiation model is specified. It is a finite value in `[0, 1]`, interpreted as
direct divided by total solar radiation. Solar geometry alone does not derive
this quantity; no package fallback is a public canonical default.

## Time inputs

Support:

- `ZonedDateTime`: convert the instant to UTC before solar calculations;
- `DateTime`: interpret explicitly as UTC and document this;
- `Date`: is not accepted as a solar timestamp; callers must provide an explicit UTC instant;
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
| dewpoint exceeds air temperature by no more than tolerance | clamp to saturation under every policy as round-off reconciliation |
| dewpoint exceeds air temperature above tolerance; clamp to saturation | `ClampDewPoint` (provisional default) |
| dewpoint exceeds air temperature above tolerance; exchange the two values for legacy-data repair | `SwapAirAndDewPoint` |
| dewpoint exceeds air temperature above tolerance; reject row | `RejectInvalidDewPoint` |

The v0.1 default is `ClampDewPoint`. It preserves the supplied air temperature
and makes a physically inconsistent dew point explicit through the diagnostic
adjustment flag. `SwapAirAndDewPoint` remains opt-in for legacy-data repair and
`RejectInvalidDewPoint` remains available for strict ingestion workflows.

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
    surface_albedo::T
    globe_diameter_m::T
    minimum_wind_speed_m_s::T
end
```

Provide validating outer constructors. The API defaults are:

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
    validation_residual_k::Union{Missing,T}
    evaluations::Int
    iterations::Int
    initial_lower_k::Union{Missing,T}
    initial_upper_k::Union{Missing,T}
    final_lower_k::Union{Missing,T}
    final_upper_k::Union{Missing,T}
    lower_location_residual::Union{Missing,T}
    upper_location_residual::Union{Missing,T}
    root_tolerance_k::T
    residual_tolerance_k::T
end

struct DiagnosticWBGTResult{T<:AbstractFloat}
    result::WBGTResult{T}
    input_status::InputStatus
    dew_point_adjusted::Bool
    wind_speed_clamped::Bool
    solar_radiation_clamped::Bool
    solar_geometry_mismatch::Bool
    direct_solar_clipped::Bool
    globe::SolverDiagnostics{T}
    natural_wet_bulb::SolverDiagnostics{T}
end
```

`validation_residual_k` is the component’s Kelvin-scale acceptance residual. Endpoint location residuals remain in the documented native units of the signed equation used for bracketing (for example, a globe energy residual may not be in Kelvin); their field names must not imply Kelvin units.

`evaluations` includes every location and final-validation residual call.
`direct_solar_clipped` reports the documented one-degree direct-beam numerical
clip; it is distinct from `solar_geometry_mismatch`, which reports supplied
radiation zeroed at or below the physical horizon.

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
- Input-adjustment flags report whether dewpoint, negative wind or negative radiation was changed before solving; they are false when the corresponding input was missing or never inspected.
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
