function _rcc_wbgt(
    combination::_RCCWBGTCombination,
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
)
    ghi_w_m2 isa Union{Missing,Real} || throw(ArgumentError(
        "ghi_w_m2 must be a Real value or missing",
    ))
    pressure_hpa isa Union{Missing,Real} || throw(ArgumentError(
        "pressure_hpa must be a Real value or missing",
    ))
    partition = _rcc_validate_scalar_partition(partition)
    T = _rcc_scalar_float_type(
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        longitude_deg,
        latitude_deg,
        ghi_w_m2,
        pressure_hpa,
        partition,
    )
    return _rcc_row_from_time(
        combination,
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        time,
        longitude_deg,
        latitude_deg,
        ghi_w_m2,
        pressure_hpa,
        partition,
        T,
    )
end

"""
    rccd167l_wbgt(air_temperature_c, relative_humidity_percent,
                  wind_speed_m_s, time, longitude_deg, latitude_deg;
                  ghi_w_m2, pressure_hpa=1010.0,
                  partition=LiljegrenClearnessFraction())

Estimate WBGT using the RCC WP-25-001 Dim167L globe and RCCNL natural
wet-bulb components. GHI is required and wind is consumed without height
conversion.
"""
function rccd167l_wbgt(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
)
    return _rcc_wbgt(
        _RCCD167LCombination(),
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        time,
        longitude_deg,
        latitude_deg;
        ghi_w_m2,
        pressure_hpa,
        partition,
    )
end

"""
    rcc_nws_wbgt(air_temperature_c, relative_humidity_percent,
                 wind_speed_m_s, time, longitude_deg, latitude_deg;
                 ghi_w_m2, pressure_hpa=1010.0,
                 partition=LiljegrenClearnessFraction())

Estimate the RCC WP-25-001 Table 5 NWS combination: Dim228 globe plus RCC-NWS
natural wet bulb. This does not reproduce the operational NDFD preprocessing
chain.
"""
function rcc_nws_wbgt(
    air_temperature_c::Union{Missing,Real},
    relative_humidity_percent::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
)
    return _rcc_wbgt(
        _RCCNWSCombination(),
        air_temperature_c,
        relative_humidity_percent,
        wind_speed_m_s,
        time,
        longitude_deg,
        latitude_deg;
        ghi_w_m2,
        pressure_hpa,
        partition,
    )
end
