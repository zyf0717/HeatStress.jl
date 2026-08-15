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
zeroed and flagged as a solar-geometry mismatch. Direct forcing is zeroed at
solar zenith angles of `89.5°` or greater; diffuse forcing remains.

The high-level Liljegren pathway uses bounded pressure-enhanced Buck
psychrometrics. A policy-resolved dew point outside `[-40, 50] °C` is
`InvalidDomain`; neither component is attempted. Air temperature has no
independent Buck-range gate. The natural-wet-bulb solver searches only the
same interval and reports `Unbracketed` if no supported root exists, while
retaining an independently accepted globe result. Temperatures are never
clamped to force them into the Buck interval.

Wind is treated as already measured at 2 m unless callers explicitly select
`LiljegrenStabilityPowerLaw()` and supply `wind_height_m`. The power-law policy
uses `Rural()` or `Urban()` exponents and either a supplied Pasquill class or
the EPA SRDT classifier. Daytime classification uses resolved GHI; nighttime
classification requires `vertical_temperature_difference_c`, defined as
upper-level minus lower-level temperature. Height adjustment precedes the
configured Liljegren minimum-wind floor. `vertical_temperature_difference_c`
is row meteorology, not `LiljegrenConfig` state.

Batch primary meteorology/time vectors are ordinally aligned. Coordinates,
pressure, irradiance components, fixed fraction, wind height, terrain,
stability class, and vertical temperature difference may be shared scalars or
row-aligned vectors. `missing` irradiance elements are reconstructed as absent.
`liljegren_wbgt!` validates all inputs, output types/lengths, and aliases
before writing any output.

RCC estimators use air temperature plus relative humidity as native humidity
inputs. GHI is mandatory and never replaced by the package clear-sky estimate.
The selected partition applies only to direct/diffuse splitting. RCC functions
consume model-ready wind without implicit height conversion. RCC-NWS accepts
zero wind in its linear natural-wet-bulb equation; RCCNL requires `wind > 0`;
Dim228 and Dim167L reject negative wind and apply their source-defined 1 m/s
floor internally. RCC radiation must be finite and non-negative. Positive GHI
with the sun at/below the geometric horizon is rejected rather than clamped.

Secondary measures use formula-native inputs. Relative humidity is always a
percentage, not a fraction. Invalid finite domains and non-finite real inputs
throw `DomainError`; any `missing` input returns `missing`.
