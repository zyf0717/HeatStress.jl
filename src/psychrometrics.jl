"""
    saturation_vapour_pressure_hpa(air_temperature_c)

Return saturation vapour pressure over liquid water in hPa using FAO-56
equation 11, `eₛ = 6.108 exp(17.27T / (T + 237.3))`, where `T` is degrees
Celsius. Inputs must be finite and within -40 to 50 degrees Celsius.
"""
function saturation_vapour_pressure_hpa(air_temperature_c::Real)
    temperature = float(air_temperature_c)
    isfinite(temperature) && -40 <= temperature <= 50 ||
        throw(ArgumentError("air_temperature_c must be finite and in [-40, 50]"))
    return _saturation_vapour_pressure_hpa_unchecked(temperature)
end

# Internal users of the standalone FAO-56 helper can bypass its public-input
# domain check. Liljegren uses the separate bounded Buck kernel below.
@inline function _saturation_vapour_pressure_hpa_unchecked(temperature::T) where {T<:AbstractFloat}
    return convert(T, 6108 // 1000) * exp(
        convert(T, 1727 // 100) * temperature /
        (temperature + convert(T, 2373 // 10)),
    )
end

"""Pressure-enhanced Buck saturation pressure over liquid water in hPa.

This private kernel is the Liljegren psychrometric relation. Its two branches
cover supercooled liquid water on `[-40, 0)` degrees Celsius and liquid water
on `[0, 50]` degrees Celsius. Callers must enforce that closed combined domain;
the kernel returns `NaN` rather than extrapolating.
"""
@inline function _buck_saturation_vapour_pressure_hpa(
        temperature_c::T,
        pressure_hpa::T,
    ) where {T<:AbstractFloat}
    minimum_c = convert(T, BUCK_MINIMUM_TEMPERATURE_C)
    maximum_c = convert(T, BUCK_MAXIMUM_TEMPERATURE_C)
    isfinite(temperature_c) && minimum_c <= temperature_c <= maximum_c &&
        isfinite(pressure_hpa) && pressure_hpa > zero(T) || return T(NaN)

    enhancement = convert(T, 10007 // 10000) +
                  convert(T, 173 // 50_000_000) * pressure_hpa
    if temperature_c < zero(T)
        exponent = convert(T, 8983 // 500) * temperature_c /
                   (convert(T, 4943 // 20) + temperature_c)
    else
        exponent = convert(T, 8751 // 500) * temperature_c /
                   (convert(T, 24097 // 100) + temperature_c)
    end
    return convert(T, 61121 // 10000) * enhancement * exp(exponent)
end

"""
    vapour_pressure(air_temperature_c, relative_humidity_percent)

Return actual vapour pressure in hPa. Relative humidity is a percentage in
the closed interval 0--100.
"""
function vapour_pressure(
        air_temperature_c::Real,
        relative_humidity_percent::Real,
    )
    temperature, humidity = promote(float(air_temperature_c), float(relative_humidity_percent))
    isfinite(humidity) && zero(humidity) <= humidity <= oftype(humidity, 100) ||
        throw(ArgumentError("relative_humidity_percent must be finite and in [0, 100]"))
    return humidity / oftype(humidity, 100) * saturation_vapour_pressure_hpa(temperature)
end

"""
    relative_humidity_from_dewpoint(air_temperature_c, dew_point_c)

Return relative humidity as a percentage calculated as
`100 eₛ(dew_point_c) / eₛ(air_temperature_c)`. Both temperatures must be
finite and within -40 to 50 degrees Celsius. Dew point is not constrained to
be at or below air temperature: supersaturation is reported explicitly as a
value above 100 percent for the policy layer to handle.
"""
function relative_humidity_from_dewpoint(air_temperature_c::Real, dew_point_c::Real)
    air_temperature, dew_point = promote(float(air_temperature_c), float(dew_point_c))
    return oftype(air_temperature, 100) *
           saturation_vapour_pressure_hpa(dew_point) /
           saturation_vapour_pressure_hpa(air_temperature)
end
