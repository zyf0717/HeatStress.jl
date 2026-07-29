# Secondary-measure API contract

```julia
wbgt_with_solar_load(natural_wet_bulb_c, globe_temperature_c, dry_bulb_temperature_c)
wbgt_without_solar_load(natural_wet_bulb_c, globe_temperature_c)
heat_index_nws(air_temperature_c, relative_humidity_percent)
wet_bulb_temperature_stull(air_temperature_c, relative_humidity_percent)
humidex(air_temperature_c, dew_point_c)
```

Each function accepts real formula-native scalar inputs, returns their promoted
floating type, propagates `missing`, and throws `DomainError` for invalid real
inputs. Ordinary broadcasting supplies array behavior.

No function silently selects a formula variant, converts an RH fraction, clamps
an invalid value or returns a diagnostic container.
