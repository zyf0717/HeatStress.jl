abstract type _RCCWBGTCombination end
struct _RCCD167LCombination <: _RCCWBGTCombination end
struct _RCCNWSCombination <: _RCCWBGTCombination end

@inline _rcc_requires_positive_wind(::_RCCD167LCombination) = true
@inline _rcc_requires_positive_wind(::_RCCNWSCombination) = false

@inline function _rcc_natural_wet_bulb(
    ::_RCCD167LCombination,
    air::T,
    humidity::T,
    wind::T,
    ghi::T,
    pressure::T,
) where {T<:AbstractFloat}
    return _rccnl_natural_wet_bulb_temperature(air, humidity, wind, ghi, pressure)
end

@inline function _rcc_natural_wet_bulb(
    ::_RCCNWSCombination,
    air::T,
    humidity::T,
    wind::T,
    ghi::T,
    pressure::T,
) where {T<:AbstractFloat}
    return _rcc_nws_natural_wet_bulb_temperature(air, humidity, wind, ghi, pressure)
end

@inline function _rcc_globe(
    ::_RCCD167LCombination,
    air::T,
    humidity::T,
    wind::T,
    ghi::T,
    zenith::T,
    fraction::T,
) where {T<:AbstractFloat}
    return _dimiceli_globe_temperature(
        air, humidity, wind, ghi, zenith, fraction,
        convert(T, RCC_DIM167L_DAY_COEFFICIENT), true,
    )
end

@inline function _rcc_globe(
    ::_RCCNWSCombination,
    air::T,
    humidity::T,
    wind::T,
    ghi::T,
    zenith::T,
    fraction::T,
) where {T<:AbstractFloat}
    return _dimiceli_globe_temperature(
        air, humidity, wind, ghi, zenith, fraction,
        convert(T, RCC_DIM228_DAY_COEFFICIENT), false,
    )
end

@inline _rcc_partition_value_type(::LiljegrenClearnessFraction) = Union{}
@inline _rcc_partition_value_type(policy::FixedDirectFraction{<:Real}) =
    typeof(float(policy.value))

function _rcc_validate_scalar_partition(policy::RadiationPartitionPolicy)
    policy isa LiljegrenClearnessFraction && return policy
    policy isa FixedDirectFraction{<:Real} && return policy
    throw(ArgumentError(
        "scalar partition must use LiljegrenClearnessFraction() or one fixed Real value",
    ))
end

function _rcc_scalar_float_type(
    air,
    humidity,
    wind,
    longitude,
    latitude,
    ghi,
    pressure,
    partition::RadiationPartitionPolicy,
)
    T = _common_float_type(air, humidity, wind, longitude, latitude, ghi, pressure)
    partition_type = _rcc_partition_value_type(partition)
    return partition_type === Union{} ? T : promote_type(T, partition_type)
end

function _rcc_row_from_time(
    combination::_RCCWBGTCombination,
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real,
    ghi_w_m2::Union{Missing,Real},
    pressure_hpa::Union{Missing,Real},
    partition::RadiationPartitionPolicy,
    ::Type{T},
) where {T<:AbstractFloat}
    _validate_longitude_deg(longitude_deg)
    _validate_latitude_deg(latitude_deg)
    if any(ismissing, (
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        ghi_w_m2,
    ))
        return WBGTResult{T}(missing, missing, missing)
    end

    air = convert(T, air_temperature_c)
    humidity = convert(T, relative_humidity_percent)
    wind = convert(T, wind_speed_m_s)
    ghi = convert(T, ghi_w_m2)
    _rcc_validate_air_temperature(air)
    _rcc_validate_relative_humidity(humidity)
    _rcc_validate_wind(wind; positive = _rcc_requires_positive_wind(combination))
    _rcc_validate_ghi(ghi)
    wet = if ismissing(pressure_hpa)
        missing
    else
        pressure = convert(T, pressure_hpa)
        _rcc_validate_pressure(pressure)
        _rcc_natural_wet_bulb(combination, air, humidity, wind, ghi, pressure)
    end
    ismissing(time) && return WBGTResult{T}(missing, wet, missing)

    zenith = convert(T, solar_zenith(time, longitude_deg, latitude_deg))
    fraction = _partition_fraction(
        partition,
        _utc_datetime(time),
        ghi,
        cos(deg2rad(zenith)),
        T,
    )
    ismissing(fraction) && throw(ArgumentError("invalid radiation partition"))
    globe = _rcc_globe(
        combination,
        air,
        humidity,
        wind,
        ghi,
        zenith,
        fraction,
    )
    wbgt = if ismissing(wet) || ismissing(globe)
        missing
    else
        convert(T, 0.1) * air + convert(T, 0.2) * globe + convert(T, 0.7) * wet
    end
    return WBGTResult{T}(wbgt, wet, globe)
end
