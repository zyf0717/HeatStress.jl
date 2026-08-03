# Constants, units and policies

## Purpose

Centralise constants, unit assumptions, validation and input policy. Prevent formula files from accumulating inconsistent magic numbers.

## Unit contract

The v0.1 numeric API uses:

| Quantity | Unit |
| --- | --- |
| air/dewpoint/component temperatures | °C at public API |
| internal thermodynamic temperatures | K |
| pressure | hPa |
| wind speed | m/s |
| radiation | W/m² |
| longitude/latitude | degrees |
| solar zenith internal | radians unless function name/doc says degrees |
| globe/wick dimensions | metres |
| relative humidity | percent at public convenience API; fraction internally where named `_fraction` |

Every public docstring must state units. Internal names must carry a suffix where ambiguity is likely: `_c`, `_k`, `_hpa`, `_m_s`, `_w_m2`, `_deg`, `_rad`, `_fraction`.

## Constants file

Create `src/constants.jl`. Define constants from the primary paper and cited supporting sources. Record source, units and any conversion; do not copy a software constant table.

At minimum define, with source comments:

```julia
const KELVIN_OFFSET = 273.15
const STEFAN_BOLTZMANN = 5.6696e-8
const SPECIFIC_HEAT_DRY_AIR = 1003.5
const MOLAR_MASS_DRY_AIR = 28.97
const MOLAR_MASS_WATER = 18.015
const UNIVERSAL_GAS_CONSTANT = 8314.34
const GAS_CONSTANT_DRY_AIR = UNIVERSAL_GAS_CONSTANT / MOLAR_MASS_DRY_AIR

const DEFAULT_PRESSURE_HPA = 1010.0
const DEFAULT_SURFACE_ALBEDO = 0.45
const DEFAULT_GLOBE_DIAMETER_M = 0.0508
const DEFAULT_MINIMUM_WIND_SPEED_M_S = 0.13
const GLOBE_EMISSIVITY = 0.95
const GLOBE_ALBEDO = 0.05
const SURFACE_EMISSIVITY = 0.999
const WICK_EMISSIVITY = 0.95
const WICK_ALBEDO = 0.4
const WICK_DIAMETER_M = 0.007
const WICK_LENGTH_M = 0.0254
```

Verify exact values against cited publications before committing. If authoritative sources disagree, record the discrepancy in `docs/src/provenance.md`, select one explicitly and add a sensitivity or compatibility note; do not silently normalise it.

Resolution: the constant/default inventory and exact-value review were
completed before release. Selected authorities and discrepancies are recorded
in `docs/src/provenance.md`; implementation and release-readiness evidence are
recorded in `tasks.md`.

## Validation rules

Implement internal validators for:

- finite longitude in `[-180, 180]`;
- finite latitude in `[-90, 90]`;
- positive finite pressure or `missing` at batch boundary;
- surface albedo in `[0, 1]`;
- direct fraction in `[0, 1]`;
- positive globe diameter;
- non-negative minimum wind speed;
- positive root and residual tolerances;
- residual tolerance no greater than `0.01 K`, used as a conservative initial package constraint and subject to scientific validation;
- non-negative dewpoint tolerance;
- positive maximum iterations.

For scalar invalid fixed configuration, throw `ArgumentError` or `DomainError`. For row-specific batch meteorology, mark the row status and return missing rather than aborting the full batch, unless array dimensions are inconsistent.

## Meteorological normalisation

Implement two composable internal scalar functions:

1. `_normalize_basic_meteorology(...)` must:

   - reject or propagate missing meteorological values according to the public contract;
   - clamp negative wind and radiation to zero;
   - apply the dewpoint policy;
   - retain the supplied non-negative wind for later component physics.

   Scalar air and dew-point temperatures must be finite. The former package
   policy requiring both values to lie within -40 through 50 °C is superseded
   for the Liljegren pathway by spec 019; the standalone spec-004
   psychrometric-helper contract is unchanged.

2. `_apply_solar_policy(...)` must accept a validated solar zenith from the
   spec-004 kernel, reject zenith outside `[0, π]`, zero radiation at and below
   the mathematical horizon (`zenith >= π/2`), and set
   `solar_geometry_mismatch` when positive supplied radiation is zeroed.

Public orchestration owns time-type validation and solar-zenith calculation.
It calls the two functions in sequence after the spec-004 source-selection gate
is resolved. Wind is floored at `minimum_wind_speed_m_s` only where required by
component physics.

Keep the distinction between supplied wind after non-negative clamping and effective wind after the model floor.

Preprocessing must also report `dew_point_adjusted`, `wind_speed_clamped`,
`solar_radiation_clamped` and `direct_solar_clipped` flags. The diagnostic APIs
expose them; value-only API documentation must state the normalization policy.

`direct_solar_clipped` identifies the separate one-degree direct-beam numerical
policy and remains distinct from the below-horizon `solar_geometry_mismatch` flag.

The v0.1 mismatch flag is deliberately strict and diagnostic-only. A noise threshold or near-horizon threshold may replace it only as an explicitly sourced or original documented policy with boundary tests; do not inherit historical thresholds from another implementation.

## Dewpoint policies

First apply the tolerance consistently:

- if `dew_point_c <= air_temperature_c`, leave both unchanged;
- if `0 < dew_point_c - air_temperature_c <= dew_point_tolerance_c`, clamp dewpoint to air temperature as round-off reconciliation under every policy;
- if the difference is above tolerance, apply the selected policy below.

### `ClampDewPoint`

Set dewpoint equal to air temperature.

### `SwapAirAndDewPoint`

Set air temperature to `max(air, dewpoint)` and dewpoint to `min(air, dewpoint)`.

### `RejectInvalidDewPoint`

Mark input `InvalidDewPoint` and do not attempt either component solver.

## Forbidden shortcuts

- Do not use `@fastmath`; it can change NaN, sign and comparison behaviour.
- Do not clamp all non-finite values to arbitrary finite values.
- Do not use a single undifferentiated `valid::Bool` without an `InputStatus`.
- Do not expose Celsius values to kernels that document Kelvin.

## Tests

Create `test/test_validation.jl` covering:

- each range boundary;
- NaN, ±Inf and missing;
- three dewpoint policies;
- dewpoint tolerance just below, equal to and above threshold;
- negative wind/radiation;
- diagnostic flags for every dewpoint/wind/radiation adjustment;
- night-time radiation zeroing;
- solar mismatch flag;
- Float32 config construction;
- invalid batch lengths abort before output mutation.

## Acceptance criteria

- constants are defined once;
- every constant has provenance or a formula comment;
- all policy branches have tests;
- no physical kernel performs public input-policy decisions independently.

## Suggested commit

`feat: add physical constants and input policies`
