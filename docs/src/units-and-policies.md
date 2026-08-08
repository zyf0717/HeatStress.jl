# Units and input policies

The numeric API accepts air, dew-point and component temperatures in °C;
pressure in hPa; wind speed in m/s; radiation in W/m²; and longitude/latitude
in degrees. Thermodynamic kernels use K. Relative humidity is percent at public
convenience boundaries and a fraction only in names ending `_fraction`. Solar
zenith is radians internally and degrees only when a public API says so.

`LiljegrenConfig` uses dimensioned field names: `dew_point_tolerance_c`,
`globe_diameter_m`, and `minimum_wind_speed_m_s`. Its solver tolerances are K.

Input preparation rejects non-finite scalar meteorology, invalid coordinates,
non-positive pressure, fixed direct fractions outside `[0, 1]`, and redundant
irradiance components that violate closure beyond the configured tolerance. A
batch boundary may represent a missing pressure as a row-level missing
meteorology result.

For high-level Liljegren calculations, policy-resolved air and dew-point
temperatures must convert to positive Kelvin, but no `[-40, 50] °C` interval is
imposed. Derived vapour pressure and transport state are checked before either
component solver. No temperature is clamped to the former interval.

GHI and DHI are horizontal; DNI is beam-normal. Supplied pairs resolve the
third component through `GHI = DHI + DNI*cos(zenith)`. A GHI-only row uses the
selected partition policy. The default `FixedDirectFraction(0.8)` preserves
the package's modern-target assumption; `LiljegrenClearnessFraction()` enables
the sourced empirical estimator. A no-input daytime row uses clear-sky GHI.

Negative wind and solar radiation are clamped to zero and reported by diagnostic
flags. Dew point above air temperature is reconciled within the configured
tolerance, then clamped, swapped, or rejected according to `DewPointPolicy`.
Solar forcing is zeroed below the computed horizon; positive supplied radiation
below that horizon sets the diagnostic-only `solar_geometry_mismatch` flag.
Positive direct radiation within one degree above the horizon instead sets
`direct_solar_clipped`; diffuse forcing remains active, and this numerical
protection is distinct from physical night-time zeroing.
The configured minimum wind is applied later by component physics, never during
public-boundary normalization.

## RCC estimated-WBGT models

RCC scalar APIs use air temperature in °C, RH in percent, model-ready wind in
m/s, GHI in W/m², station pressure in hPa, and the common timestamp/coordinate
contract. The component globe functions take solar zenith in degrees and a
direct-horizontal/GHI fraction. `ghi_w_m2` is required by composed calls.

The NWS psychrometric component uses exactly five published Newton updates.
RCCNL requires strictly positive wind. Dim228 and Dim167L use a fixed 1 m/s
wind floor and treat `zenith >= 87°` as night (`h=0`). No `LiljegrenConfig`
field changes these fixed source contracts. Invalid domains throw
`ArgumentError`; a missing scientific input returns `missing` or missing result
fields.

## Scalar Liljegren model

`diagnose_liljegren` is the canonical scalar calculation; `liljegren_wbgt`,
`globe_temperature`, and `natural_wet_bulb_temperature` discard parts of that
same diagnostic result. Complete WBGT is only
returned when both component roots pass their independent Kelvin-scale
residual validation; a diagnostic preserves either valid component when the
other fails.

`surface_albedo` affects reflected shortwave forcing for both instruments.
`globe_diameter_m` affects globe convection. `minimum_wind_speed_m_s` is the
model wind floor used by both component balances, including a measured zero
wind. Solver location and residual tolerances are independent: changing the
latter cannot accept an unbracketed or non-finite location attempt.

```@docs
HeatStress.diagnose_liljegren
HeatStress.liljegren_wbgt
HeatStress.globe_temperature
HeatStress.natural_wet_bulb_temperature
```

## Public types

```@docs
DewPointPolicy
InputStatus
FailureReason
SolverConfig
LiljegrenConfig
RadiationPartitionPolicy
FixedDirectFraction
LiljegrenClearnessFraction
WBGTResult
IrradianceDiagnostics
SolverDiagnostics
DiagnosticWBGTResult
WBGTBatchResult
IrradianceDiagnosticsBatch
SolverDiagnosticsBatch
DiagnosticWBGTBatchResult
HeatStress.liljegren_wbgt_batch
HeatStress.liljegren_wbgt!
HeatStress.diagnose_liljegren_batch
```

## Solar and psychrometric kernels

Solar timestamps are explicit UTC `DateTime` values or `ZonedDateTime` values
converted to UTC. Longitude is positive east and both coordinate inputs are
degrees. Solar zenith is returned in degrees; values above 90° are below the
geometric horizon. `Date` is intentionally unsupported.

Standalone psychrometric-helper temperatures are Celsius and
saturation/actual vapour pressures are hPa. Relative humidity arguments and
results are percentages. These helper inputs retain their released -40--50 °C
contract; `vapour_pressure` also requires humidity in 0--100 percent. This
helper contract is separate from high-level Liljegren input preparation.
Invalid inputs throw `ArgumentError`.

```@docs
HeatStress.solar_zenith
HeatStress.solar_zenith_batch
HeatStress.saturation_vapour_pressure_hpa
HeatStress.vapour_pressure
HeatStress.relative_humidity_from_dewpoint
```
