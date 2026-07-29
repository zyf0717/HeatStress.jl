@inline _celsius_to_fahrenheit(value::T) where {T<:AbstractFloat} =
    muladd(convert(T, 9 // 5), value, convert(T, 32))

@inline _fahrenheit_to_celsius(value::T) where {T<:AbstractFloat} =
    (value - convert(T, 32)) * convert(T, 5 // 9)

@inline function _simple_heat_index_f(temperature_f::T, humidity::T) where {T<:AbstractFloat}
    estimate = convert(T, 1 // 2) * (
        temperature_f +
        convert(T, 61) +
        convert(T, 6 // 5) * (temperature_f - convert(T, 68)) +
        convert(T, 47 // 500) * humidity
    )
    return convert(T, 1 // 2) * (estimate + temperature_f)
end

@inline function _rothfusz_heat_index_f(temperature_f::T, humidity::T) where {T<:AbstractFloat}
    temperature_squared = temperature_f * temperature_f
    humidity_squared = humidity * humidity
    return convert(T, -42379 // 1000) +
           convert(T, 204901523 // 100000000) * temperature_f +
           convert(T, 1014333127 // 100000000) * humidity -
           convert(T, 22475541 // 100000000) * temperature_f * humidity -
           convert(T, 683783 // 100000000) * temperature_squared -
           convert(T, 5481717 // 100000000) * humidity_squared +
           convert(T, 61437 // 50000000) * temperature_squared * humidity +
           convert(T, 42641 // 50000000) * temperature_f * humidity_squared -
           convert(T, 199 // 100000000) * temperature_squared * humidity_squared
end

@inline function _adjust_heat_index_f(
        heat_index_f::T,
        temperature_f::T,
        humidity::T,
    ) where {T<:AbstractFloat}
    if humidity < convert(T, 13) &&
            convert(T, 80) <= temperature_f <= convert(T, 112)
        adjustment = (convert(T, 13) - humidity) / convert(T, 4) *
                     sqrt(
            (convert(T, 17) - abs(temperature_f - convert(T, 95))) /
            convert(T, 17),
        )
        return heat_index_f - adjustment
    elseif humidity > convert(T, 85) &&
            convert(T, 80) <= temperature_f <= convert(T, 87)
        adjustment = (humidity - convert(T, 85)) / convert(T, 10) *
                     (convert(T, 87) - temperature_f) / convert(T, 5)
        return heat_index_f + adjustment
    end
    return heat_index_f
end

"""
    heat_index_nws(air_temperature_c, relative_humidity_percent)

Return the US National Weather Service operational heat index in degrees
Celsius. Inputs are air temperature in degrees Celsius and relative humidity
as a percentage in `[0, 100]`.

The implementation follows the NWS procedure: the simple
Steadman-consistent estimate and averaging step determine whether to use the
Rothfusz regression, after which the documented low- or high-humidity
adjustment is applied. Heat index represents shaded conditions and does not
account for wind, radiant heat or workload. The NWS warns that the regression
is not valid for extreme conditions but publishes no exact outer temperature
boundary.

Inputs must be finite. A `missing` input returns `missing`.
"""
@inline function heat_index_nws(
        air_temperature_c::_MaybeReal,
        relative_humidity_percent::_MaybeReal,
    )
    any(ismissing, (air_temperature_c, relative_humidity_percent)) && return missing
    temperature, humidity =
        promote(float(air_temperature_c), float(relative_humidity_percent))
    _require_finite(temperature, "air_temperature_c")
    _require_finite(humidity, "relative_humidity_percent")
    zero(humidity) <= humidity <= convert(typeof(humidity), 100) ||
        throw(DomainError(humidity, "relative_humidity_percent must be in [0, 100]"))

    temperature_f = _celsius_to_fahrenheit(temperature)
    simple_heat_index_f = _simple_heat_index_f(temperature_f, humidity)
    heat_index_f = if simple_heat_index_f < convert(typeof(temperature_f), 80)
        simple_heat_index_f
    else
        _adjust_heat_index_f(
            _rothfusz_heat_index_f(temperature_f, humidity),
            temperature_f,
            humidity,
        )
    end
    return _fahrenheit_to_celsius(heat_index_f)
end
