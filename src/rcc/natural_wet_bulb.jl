@inline function _rcc_natural_wet_bulb_inputs(
    air_temperature_c::T,
    relative_humidity_percent::T,
    wind_speed_m_s::T,
    ghi_w_m2::T,
    pressure_hpa::T;
    positive_wind::Bool,
) where {T<:AbstractFloat}
    _rcc_validate_air_temperature(air_temperature_c)
    _rcc_validate_relative_humidity(relative_humidity_percent)
    _rcc_validate_wind(wind_speed_m_s; positive = positive_wind)
    _rcc_validate_ghi(ghi_w_m2)
    _rcc_validate_pressure(pressure_hpa)
    return _psychrometric_wet_bulb_nws(
        air_temperature_c,
        relative_humidity_percent,
        pressure_hpa,
    )
end

function _rcc_nws_natural_wet_bulb_temperature(
    air_temperature_c::T,
    relative_humidity_percent::T,
    wind_speed_m_s::T,
    ghi_w_m2::T,
    pressure_hpa::T,
) where {T<:AbstractFloat}
    wet_bulb_c = _rcc_natural_wet_bulb_inputs(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa;
        positive_wind = false,
    )
    ismissing(wet_bulb_c) && return missing
    wet_bulb_depression_c = air_temperature_c - wet_bulb_c
    return wet_bulb_c + convert(T, 0.001651) * ghi_w_m2 -
           convert(T, 0.09555) * wind_speed_m_s +
           convert(T, 0.13235) * wet_bulb_depression_c +
           convert(T, 0.20249)
end

function _rccnl_natural_wet_bulb_temperature(
    air_temperature_c::T,
    relative_humidity_percent::T,
    wind_speed_m_s::T,
    ghi_w_m2::T,
    pressure_hpa::T,
) where {T<:AbstractFloat}
    wet_bulb_c = _rcc_natural_wet_bulb_inputs(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa;
        positive_wind = true,
    )
    ismissing(wet_bulb_c) && return missing
    wet_bulb_depression_c = air_temperature_c - wet_bulb_c
    numerator = -convert(T, 3e-6) * ghi_w_m2^2 +
                convert(T, 0.0046) * ghi_w_m2 +
                convert(T, 0.135) * wet_bulb_depression_c
    return wet_bulb_c + numerator / wind_speed_m_s^convert(T, 0.15) -
           convert(T, 0.0443)
end

function _rcc_component_inputs(
    air_temperature_c,
    relative_humidity_percent,
    wind_speed_m_s,
    ghi_w_m2,
    pressure_hpa,
)
    any(ismissing, (
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa,
    )) && return nothing
    T = _common_float_type(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa,
    )
    return T, convert.(T, (
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa,
    ))
end

"""Return RCC WP-25-001 equation 8 natural wet-bulb temperature in °C."""
function rcc_nws_natural_wet_bulb_temperature(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    ghi_w_m2::Union{Missing,Real};
    pressure_hpa::Union{Missing,Real} = DEFAULT_PRESSURE_HPA,
)
    inputs = _rcc_component_inputs(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa,
    )
    isnothing(inputs) && return missing
    _, values = inputs
    return _rcc_nws_natural_wet_bulb_temperature(values...)
end

"""
Return RCC WP-25-001 equation 9 nonlinear natural wet-bulb temperature in °C.
Wind must be strictly positive; the source defines no zero-wind floor.
"""
function rccnl_natural_wet_bulb_temperature(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    ghi_w_m2::Union{Missing,Real};
    pressure_hpa::Union{Missing,Real} = DEFAULT_PRESSURE_HPA,
)
    inputs = _rcc_component_inputs(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        pressure_hpa,
    )
    isnothing(inputs) && return missing
    _, values = inputs
    return _rccnl_natural_wet_bulb_temperature(values...)
end
