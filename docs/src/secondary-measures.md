# Secondary heat measures

The direct measures below are distinct environmental indices with different
inputs and assumptions. They are not interchangeable exposure limits or
individual medical assessments.

## Measured-component WBGT

`wbgt_with_solar_load` uses:

```math
WBGT = 0.7T_{nwb} + 0.2T_g + 0.1T_{db}.
```

`wbgt_without_solar_load` uses:

```math
WBGT = 0.7T_{nwb} + 0.3T_g.
```

All component temperatures are measured in degrees Celsius. The equations and
environment distinction follow the
[OSHA Technical Manual](https://www.osha.gov/otm/section-3-health-hazards/chapter-4).
Representative instruments, placement, exposure averaging, workload, clothing,
and acclimatisation remain separate assessment concerns.

## NWS heat index

`heat_index_nws(air_temperature_c, relative_humidity_percent)` follows the
[National Weather Service operational procedure](https://www.weather.gov/ctp/heat).
It evaluates the simple estimate first, switches to the Rothfusz regression
when the averaged estimate reaches 80°F, and applies the documented low- or
high-humidity adjustment.

The returned value is degrees Celsius. RH must be in `[0, 100]`. Heat index
represents shaded conditions and does not account for wind, direct sunlight,
radiant sources, clothing, or workload. The NWS notes that the regression is
not valid for extreme conditions but publishes no exact outer temperature
boundary for the complete operational procedure.

## Stull wet-bulb approximation

`wet_bulb_temperature_stull(air_temperature_c, relative_humidity_percent)`
implements Stull (2011), equation 1. Its published numeric range is air
temperature `[-20, 50]` °C and RH `[5, 99]`% at 101.325 kPa. The source also
qualitatively excludes cold/low-humidity combinations without defining a
numeric boundary. Reported approximation errors range from about -1 to
+0.65°C over the applicable region.

This is a psychrometric wet-bulb approximation, not the natural wet-bulb
component measured or modeled for WBGT.

## Humidex

`humidex(air_temperature_c, dew_point_c)` follows the standard
[Environment and Climate Change Canada formula](https://www.wateroffice.ec.gc.ca/glossary_e.html?wbdisable=true):

```math
H = T + 0.5555(e - 10),
```

where vapour pressure ``e`` is calculated in hPa from dew point in Kelvin using
the ECCC constants. Humidex is dimensionless but conventionally communicated
on a Celsius-like scale. ECCC's hourly display thresholds are not imposed on
formula evaluation.

## Broadcasting and failures

All functions are scalar:

```julia
heat_index_nws.([30.0, 32.0], [60.0, 70.0])
```

Inputs are promoted to a common floating type; all-Float32 calls return
Float32. A `missing` input returns `missing`. Non-finite or invalid-domain real
inputs throw `DomainError`.

## API reference

```@docs
wbgt_with_solar_load
wbgt_without_solar_load
heat_index_nws
wet_bulb_temperature_stull
humidex
```
