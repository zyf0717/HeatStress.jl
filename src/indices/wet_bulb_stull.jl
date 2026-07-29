"""
    wet_bulb_temperature_stull(air_temperature_c, relative_humidity_percent)

Return the Stull (2011) equation 1 approximation of wet-bulb temperature in
degrees Celsius from air temperature in degrees Celsius and relative humidity
in percent.

The published numeric applicability range is `-20 <= air_temperature_c <= 50`
and `5 <= relative_humidity_percent <= 99` at standard sea-level pressure
(101.325 kPa). The source also excludes some combinations having both low
humidity and cold temperature but gives no numerical boundary for that region;
callers must account for that qualitative limitation. Reported approximation
errors over the valid region range from about -1 to +0.65 degrees Celsius.

Inputs outside the published numeric bounds or non-finite inputs throw
`DomainError`. A `missing` input returns `missing`.
"""
@inline function wet_bulb_temperature_stull(
        air_temperature_c::_MaybeReal,
        relative_humidity_percent::_MaybeReal,
    )
    any(ismissing, (air_temperature_c, relative_humidity_percent)) && return missing
    temperature, humidity =
        promote(float(air_temperature_c), float(relative_humidity_percent))
    _require_finite(temperature, "air_temperature_c")
    _require_finite(humidity, "relative_humidity_percent")
    T = typeof(temperature)
    convert(T, -20) <= temperature <= convert(T, 50) ||
        throw(DomainError(temperature, "air_temperature_c must be in [-20, 50]"))
    convert(T, 5) <= humidity <= convert(T, 99) ||
        throw(DomainError(humidity, "relative_humidity_percent must be in [5, 99]"))

    return temperature *
           atan(convert(T, 151977 // 1000000) *
                sqrt(humidity + convert(T, 8313659 // 1000000))) +
           atan(temperature + humidity) -
           atan(humidity - convert(T, 1676331 // 1000000)) +
           convert(T, 195919 // 50000000) * humidity * sqrt(humidity) *
           atan(convert(T, 23101 // 1000000) * humidity) -
           convert(T, 937207 // 200000)
end
