# NWS psychrometric wet-bulb procedure reproduced from RCC WP-25-001,
# Appendix B. Temperatures are Celsius at public boundaries and Kelvin only
# where the published procedure explicitly requires it.

@inline function _rcc_validate_air_temperature(value::T) where {T<:AbstractFloat}
    isfinite(value) && value + convert(T, KELVIN_OFFSET) > zero(T) ||
        throw(ArgumentError("air_temperature_c must be finite and above absolute zero"))
    return value
end

@inline function _rcc_validate_relative_humidity(value::T) where {T<:AbstractFloat}
    isfinite(value) && zero(T) <= value <= convert(T, 100) ||
        throw(ArgumentError("relative_humidity_percent must be finite and in [0, 100]"))
    return value
end

@inline function _rcc_validate_wind(value::T; positive::Bool = false) where {T<:AbstractFloat}
    valid = positive ? value > zero(T) : value >= zero(T)
    isfinite(value) && valid || throw(ArgumentError(
        positive ? "wind_speed_m_s must be finite and positive" :
                   "wind_speed_m_s must be finite and non-negative",
    ))
    return value
end

@inline function _rcc_validate_ghi(value::T) where {T<:AbstractFloat}
    isfinite(value) && value >= zero(T) ||
        throw(ArgumentError("ghi_w_m2 must be finite and non-negative"))
    return value
end

@inline function _rcc_validate_pressure(value::T) where {T<:AbstractFloat}
    isfinite(value) && value > zero(T) ||
        throw(ArgumentError("pressure_hpa must be finite and positive"))
    return value
end

@inline function _nws_saturation_vapour_pressure_hpa(temperature_c::T) where {T<:AbstractFloat}
    temperature_k = temperature_c + convert(T, KELVIN_OFFSET)
    denominator = temperature_k - convert(T, 32.18)
    iszero(denominator) && return T(NaN)
    y = (temperature_k - convert(T, KELVIN_OFFSET)) / denominator
    return convert(T, 1.004 * 6.1121) * exp(convert(T, 17.502) * y)
end

@inline function _nws_actual_vapour_pressure_hpa(
    air_temperature_c::T,
    relative_humidity_percent::T,
) where {T<:AbstractFloat}
    return relative_humidity_percent / convert(T, 100) *
           _nws_saturation_vapour_pressure_hpa(air_temperature_c)
end

@inline function _nws_dew_point_c(vapour_pressure_hpa::T) where {T<:AbstractFloat}
    vapour_pressure_hpa > zero(T) || return missing
    z = log(vapour_pressure_hpa / convert(T, 1.004 * 6.1121))
    denominator = convert(T, 17.502) - z
    iszero(denominator) && return missing
    dew_point_c = convert(T, 240.97) * z / denominator
    return isfinite(dew_point_c) ? dew_point_c : missing
end

@inline function _nws_base10_saturation_hpa(temperature_c::T) where {T<:AbstractFloat}
    denominator = temperature_c + convert(T, 237.3)
    iszero(denominator) && return T(NaN)
    exponent = convert(T, 7.5) * temperature_c / denominator
    return convert(T, 6.11) * convert(T, 10)^exponent
end

function _psychrometric_wet_bulb_nws(
    air_temperature_c::T,
    relative_humidity_percent::T,
    pressure_hpa::T,
) where {T<:AbstractFloat}
    _rcc_validate_air_temperature(air_temperature_c)
    _rcc_validate_relative_humidity(relative_humidity_percent)
    _rcc_validate_pressure(pressure_hpa)

    vapour_pressure = _nws_actual_vapour_pressure_hpa(
        air_temperature_c,
        relative_humidity_percent,
    )
    isfinite(vapour_pressure) || return missing
    dew_point_c = _nws_dew_point_c(vapour_pressure)
    ismissing(dew_point_c) && return missing

    psychrometric_factor = convert(T, 0.0006355) * pressure_hpa
    saturated_air = _nws_base10_saturation_hpa(air_temperature_c)
    saturated_dew = _nws_base10_saturation_hpa(dew_point_c)
    all(isfinite, (saturated_air, saturated_dew)) || return missing
    vapour_difference = saturated_air - saturated_dew
    temperature_difference = air_temperature_c - dew_point_c
    wet_bulb_c = if iszero(temperature_difference)
        air_temperature_c
    else
        slope = vapour_difference / temperature_difference
        denominator = psychrometric_factor + slope
        iszero(denominator) && return missing
        (air_temperature_c * psychrometric_factor + dew_point_c * slope) /
            denominator
    end

    # RCC WP-25-001 Appendix B fixes the update count at exactly five.
    for _ in 1:5
        wet_bulb_k = wet_bulb_c + convert(T, KELVIN_OFFSET)
        iszero(wet_bulb_k) && return missing
        saturated_wet = _nws_base10_saturation_hpa(wet_bulb_c)
        isfinite(saturated_wet) || return missing
        residual = psychrometric_factor * (air_temperature_c - wet_bulb_c) -
                   (saturated_wet - saturated_dew)
        derivative = saturated_wet * (
            convert(T, 0.0091) - convert(T, 6106.4) / wet_bulb_k^2
        ) - psychrometric_factor
        iszero(derivative) && return missing
        wet_bulb_c = wet_bulb_k - residual / derivative - convert(T, KELVIN_OFFSET)
        isfinite(wet_bulb_c) || return missing
    end
    return wet_bulb_c
end

"""
    psychrometric_wet_bulb_nws(air_temperature_c,
                               relative_humidity_percent;
                               pressure_hpa=1010.0)

Calculate psychrometric wet-bulb temperature in °C using the fixed five-update
NWS procedure published in RCC WP-25-001 Appendix B. A zero-RH state returns
`missing` because the procedure's dew point is not finite.
"""
function psychrometric_wet_bulb_nws(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real};
    pressure_hpa::Union{Missing,Real} = DEFAULT_PRESSURE_HPA,
)
    any(ismissing, (air_temperature_c, relative_humidity_percent, pressure_hpa)) &&
        return missing
    T = _common_float_type(
        air_temperature_c,
        relative_humidity_percent,
        pressure_hpa,
    )
    return _psychrometric_wet_bulb_nws(
        convert(T, air_temperature_c),
        convert(T, relative_humidity_percent),
        convert(T, pressure_hpa),
    )
end
