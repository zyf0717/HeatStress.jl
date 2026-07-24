# Inputs and policies

The v0.1 numeric API accepts air, dew-point and component temperatures in °C;
pressure in hPa; wind speed in m/s; radiation in W/m²; and longitude/latitude
in degrees. Thermodynamic kernels use K. Relative humidity is percent at the
public convenience boundary and a fraction only in names ending `_fraction`.

`DateTime` means UTC. `ZonedDateTime` is converted to its UTC instant; a
`Date` is deliberately unsupported because solar geometry needs a time of day.
Longitude is positive east and latitude positive north.

`direct_fraction` is direct divided by total solar radiation and is required:
v0.1 does not infer a radiation partition. Negative wind and radiation are
clamped to zero with diagnostic flags. Dew point above air temperature is
reconciled within `dew_point_tolerance_c`, then clamped, swapped, or rejected
by `DewPointPolicy`. Positive radiation at/below the geometric horizon is
zeroed and flagged as a solar-geometry mismatch. Direct forcing is clipped in
the one-degree near-horizon protection interval; diffuse forcing remains.

Batch primary meteorology/time vectors are ordinally aligned. Coordinates,
pressure, and direct fraction may be shared scalars or row-aligned vectors.
`liljegren_wbgt!` validates all inputs, output types/lengths, and aliases
before writing any output.
