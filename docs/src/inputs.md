# Inputs and policies

The numeric API accepts air, dew-point and component temperatures in °C;
pressure in hPa; wind speed in m/s; radiation in W/m²; and longitude/latitude
in degrees. Thermodynamic kernels use K. Relative humidity is percent at the
public convenience boundary and a fraction only in names ending `_fraction`.

`DateTime` means UTC. `ZonedDateTime` is converted to its UTC instant; a
`Date` is deliberately unsupported because solar geometry needs a time of day.
Longitude is positive east and latitude positive north.

GHI and DHI are horizontal; DNI is normal to the solar beam. Any combination
may be supplied through `ghi_w_m2`, `dni_w_m2`, and `dhi_w_m2`. Measured pairs
are reconciled using `GHI = DHI + DNI*cos(zenith)`. Underdetermined rows use
`FixedDirectFraction(0.8)` by default or the opt-in
`LiljegrenClearnessFraction()` estimator. With no component, GHI is estimated
as clear sky. Negative wind and irradiance are clamped to zero with diagnostic
flags. Dew point above air temperature is
reconciled within `dew_point_tolerance_c`, then clamped, swapped, or rejected
by `DewPointPolicy`. Positive radiation at/below the geometric horizon is
zeroed and flagged as a solar-geometry mismatch. Direct forcing is clipped in
the one-degree near-horizon protection interval; diffuse forcing remains.

Batch primary meteorology/time vectors are ordinally aligned. Coordinates,
pressure, irradiance components, and fixed fraction may be shared scalars or
row-aligned vectors. `missing` irradiance elements are reconstructed as absent.
`liljegren_wbgt!` validates all inputs, output types/lengths, and aliases
before writing any output.

Secondary measures use formula-native inputs. Relative humidity is always a
percentage, not a fraction. Invalid finite domains and non-finite real inputs
throw `DomainError`; any `missing` input returns `missing`.
