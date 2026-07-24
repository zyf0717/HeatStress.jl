# Units and input policies

The v0.1 numeric API accepts air, dew-point and component temperatures in °C;
pressure in hPa; wind speed in m/s; radiation in W/m²; and longitude/latitude
in degrees. Thermodynamic kernels use K. Relative humidity is percent at public
convenience boundaries and a fraction only in names ending `_fraction`. Solar
zenith is radians internally and degrees only when a public API says so.

`LiljegrenConfig` uses dimensioned field names: `dew_point_tolerance_c`,
`globe_diameter_m`, and `minimum_wind_speed_m_s`. Its solver tolerances are K.

Input preparation rejects non-finite scalar meteorology, invalid coordinates,
non-positive pressure, and direct fractions outside `[0, 1]`. A batch boundary
may represent a missing pressure as a row-level missing meteorology result.

Negative wind and solar radiation are clamped to zero and reported by diagnostic
flags. Dew point above air temperature is reconciled within the configured
tolerance, then clamped, swapped, or rejected according to `DewPointPolicy`.
Solar forcing is zeroed below the computed horizon; positive supplied radiation
below that horizon sets the diagnostic-only `solar_geometry_mismatch` flag.
The configured minimum wind is applied later by component physics, never during
public-boundary normalization.

## Public types

```@docs
DewPointPolicy
SolarTimeMode
InputStatus
FailureReason
SolverConfig
LiljegrenConfig
WBGTResult
SolverDiagnostics
DiagnosticWBGTResult
WBGTBatchResult
```
