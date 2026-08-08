# Fixed Dimiceli/RCC model constants. These intentionally do not reuse the
# close but distinct Liljegren constants in src/constants.jl.
const RCC_DIMICELI_STEFAN_BOLTZMANN = 5.67e-8
const RCC_DIMICELI_GLOBE_EMISSIVITY = 0.95
const RCC_DIMICELI_SURFACE_ALBEDO = 0.2
const RCC_DIMICELI_MINIMUM_WIND_SPEED_M_S = 1.0
const RCC_DIMICELI_DAY_ZENITH_DEG = 87.0
const RCC_DIM228_DAY_COEFFICIENT = 0.228
const RCC_DIM167L_DAY_COEFFICIENT = 0.167
const RCC_DIMICELI_WIND_EXPONENT = 0.58
const RCC_DIMICELI_TANGENT_SLOPE = 256_000.0
const RCC_DIMICELI_TANGENT_INTERCEPT = 7_680_000.0

@inline function _rcc_validate_zenith(value::T) where {T<:AbstractFloat}
    isfinite(value) && zero(T) <= value <= convert(T, 180) ||
        throw(ArgumentError("solar_zenith_deg must be finite and in [0, 180]"))
    return value
end

@inline function _rcc_validate_direct_fraction(value::T) where {T<:AbstractFloat}
    isfinite(value) && zero(T) <= value <= one(T) ||
        throw(ArgumentError("direct_fraction must be finite and in [0, 1]"))
    return value
end

@inline function _rcc_atmospheric_emissivity(
    air_temperature_c::T,
    relative_humidity_percent::T,
) where {T<:AbstractFloat}
    vapour_pressure = _nws_actual_vapour_pressure_hpa(
        air_temperature_c,
        relative_humidity_percent,
    )
    isfinite(vapour_pressure) && vapour_pressure >= zero(T) || return T(NaN)
    return convert(T, 0.575) * vapour_pressure^convert(T, 1 // 7)
end

@inline function _rcc_direct_gain(
    direct_fraction::T,
    cos_zenith::T,
    sigma::T,
) where {T<:AbstractFloat}
    iszero(direct_fraction) && return zero(T)
    cos_zenith > zero(T) || throw(ArgumentError(
        "positive direct fraction requires solar zenith below 90 degrees",
    ))
    return direct_fraction / (convert(T, 4) * sigma * cos_zenith)
end

function _dimiceli_globe_temperature(
    air_temperature_c::T,
    relative_humidity_percent::T,
    wind_speed_m_s::T,
    ghi_w_m2::T,
    solar_zenith_deg::T,
    direct_fraction::T,
    day_coefficient::T,
    liljegren_heat_gain::Bool,
) where {T<:AbstractFloat}
    _rcc_validate_air_temperature(air_temperature_c)
    _rcc_validate_relative_humidity(relative_humidity_percent)
    _rcc_validate_wind(wind_speed_m_s)
    _rcc_validate_ghi(ghi_w_m2)
    _rcc_validate_zenith(solar_zenith_deg)
    _rcc_validate_direct_fraction(direct_fraction)
    ghi_w_m2 > zero(T) && solar_zenith_deg >= convert(T, 90) &&
        throw(ArgumentError(
            "positive ghi_w_m2 requires solar zenith below 90 degrees",
        ))

    sigma = convert(T, RCC_DIMICELI_STEFAN_BOLTZMANN)
    globe_emissivity = convert(T, RCC_DIMICELI_GLOBE_EMISSIVITY)
    surface_albedo = convert(T, RCC_DIMICELI_SURFACE_ALBEDO)
    atmospheric_emissivity = _rcc_atmospheric_emissivity(
        air_temperature_c,
        relative_humidity_percent,
    )
    isfinite(atmospheric_emissivity) || return missing

    solar_gain = if iszero(ghi_w_m2)
        zero(T)
    else
        cos_zenith = cos(deg2rad(solar_zenith_deg))
        direct_gain = _rcc_direct_gain(direct_fraction, cos_zenith, sigma)
        diffuse_fraction = one(T) - direct_fraction
        diffuse_gain = if liljegren_heat_gain
            (diffuse_fraction + surface_albedo) / (convert(T, 2) * sigma)
        else
            (one(T) + surface_albedo) * diffuse_fraction / sigma
        end
        ghi_w_m2 * (direct_gain + diffuse_gain)
    end
    longwave_gain = if liljegren_heat_gain
        (one(T) + atmospheric_emissivity) * air_temperature_c^4 / convert(T, 2)
    else
        atmospheric_emissivity * air_temperature_c^4
    end
    b = solar_gain + longwave_gain

    daytime = solar_zenith_deg < convert(T, RCC_DIMICELI_DAY_ZENITH_DEG)
    h = daytime ? day_coefficient : zero(T)
    wind_m_hr = max(
        wind_speed_m_s,
        convert(T, RCC_DIMICELI_MINIMUM_WIND_SPEED_M_S),
    ) * convert(T, 3600)
    c = h * wind_m_hr^convert(T, RCC_DIMICELI_WIND_EXPONENT) /
        (globe_emissivity * sigma)
    result = (
        b + c * air_temperature_c +
        convert(T, RCC_DIMICELI_TANGENT_INTERCEPT)
    ) / (c + convert(T, RCC_DIMICELI_TANGENT_SLOPE))
    return isfinite(result) ? result : missing
end

function _rcc_globe_component_inputs(
    air_temperature_c,
    relative_humidity_percent,
    wind_speed_m_s,
    ghi_w_m2,
    solar_zenith_deg,
    direct_fraction,
)
    any(ismissing, (
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        solar_zenith_deg,
        direct_fraction,
    )) && return nothing
    T = _common_float_type(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        solar_zenith_deg,
        direct_fraction,
    )
    return T, convert.(T, (
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        solar_zenith_deg,
        direct_fraction,
    ))
end

"""
Return the WP-25-001 Dim167L globe temperature in °C from model-ready wind,
GHI, geometric solar zenith and direct-horizontal/GHI fraction.
"""
function dim167l_globe_temperature(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    ghi_w_m2::Union{Missing,Real},
    solar_zenith_deg::Union{Missing,Real},
    direct_fraction::Union{Missing,Real},
)
    inputs = _rcc_globe_component_inputs(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        solar_zenith_deg,
        direct_fraction,
    )
    isnothing(inputs) && return missing
    T, values = inputs
    return _dimiceli_globe_temperature(
        values...,
        convert(T, RCC_DIM167L_DAY_COEFFICIENT),
        true,
    )
end

"""
Return the WP-25-001 Dim228 globe temperature in °C from model-ready wind,
GHI, geometric solar zenith and direct-horizontal/GHI fraction.
"""
function dim228_globe_temperature(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    ghi_w_m2::Union{Missing,Real},
    solar_zenith_deg::Union{Missing,Real},
    direct_fraction::Union{Missing,Real},
)
    inputs = _rcc_globe_component_inputs(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
        solar_zenith_deg,
        direct_fraction,
    )
    isnothing(inputs) && return missing
    T, values = inputs
    return _dimiceli_globe_temperature(
        values...,
        convert(T, RCC_DIM228_DAY_COEFFICIENT),
        false,
    )
end
