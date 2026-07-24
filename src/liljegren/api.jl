@inline function _config_as_type(::Type{T}, config::LiljegrenConfig) where {T<:AbstractFloat}
    solver = config.solver
    return LiljegrenConfig{T}(
        SolverConfig{T}(
            convert(T, solver.root_tolerance_k),
            convert(T, solver.residual_tolerance_k),
            solver.maximum_iterations,
        ),
        config.dew_point_policy,
        convert(T, config.dew_point_tolerance_c),
        convert(T, config.surface_albedo),
        convert(T, config.globe_diameter_m),
        convert(T, config.minimum_wind_speed_m_s),
    )
end

@inline _scalar_float_type(::Type{Missing}) = Union{}
@inline _scalar_float_type(::Type{T}) where {T<:Real} = typeof(float(zero(T)))

@noinline function _reject_public_pressure_hpa(function_object, arguments...)
    throw(MethodError(function_object, arguments))
end

@inline function _scalar_input_type(
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    solar_radiation_w_m2,
    pressure_hpa,
    direct_fraction,
    longitude_deg,
    latitude_deg,
    config::LiljegrenConfig,
)
    return promote_type(
        _scalar_float_type(typeof(air_temperature_c)),
        _scalar_float_type(typeof(dew_point_c)),
        _scalar_float_type(typeof(wind_speed_m_s)),
        _scalar_float_type(typeof(solar_radiation_w_m2)),
        _scalar_float_type(typeof(pressure_hpa)),
        _scalar_float_type(typeof(direct_fraction)),
        _scalar_float_type(typeof(longitude_deg)),
        _scalar_float_type(typeof(latitude_deg)),
        _scalar_float_type(typeof(config.dew_point_tolerance_c)),
    )
end

function _liljegren_scalar(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa::Union{Missing,Real} = DEFAULT_PRESSURE_HPA,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
    mode::_ScalarResultMode = _DiagnosticMode(),
)
    input_type = _scalar_input_type(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        pressure_hpa, direct_fraction, longitude_deg, latitude_deg, config,
    )
    typed_config = _config_as_type(input_type, config)
    row_result = _liljegren_row_from_time(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg, pressure_hpa, direct_fraction, typed_config, mode,
    )
    return _scalar_public_result(input_type, row_result, mode)
end

"""
    diagnose_liljegren(air_temperature_c, dew_point_c, wind_speed_m_s,
                       solar_radiation_w_m2, time, longitude_deg, latitude_deg;
                       pressure_hpa=1010, direct_fraction, config=LiljegrenConfig())

Return a `DiagnosticWBGTResult` for the scalar Liljegren outdoor WBGT model.
Temperatures are °C, wind is m/s, radiation is W/m², pressure is hPa, and
`direct_fraction` is direct divided by total radiation. `DateTime` is UTC;
`ZonedDateTime` is converted to its UTC instant.
"""
function diagnose_liljegren(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_pressure_hpa(
        diagnose_liljegren,
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg,
    )
    return _liljegren_scalar(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg;
        pressure_hpa, direct_fraction, config, mode = _DiagnosticMode(),
    )
end

"""Return the scalar Liljegren WBGT result (°C components and WBGT)."""
function liljegren_wbgt(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_pressure_hpa(
        liljegren_wbgt,
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg,
    )
    return _liljegren_scalar(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg;
        pressure_hpa, direct_fraction, config, mode = _ValueMode(),
    )
end

"""Return scalar Liljegren globe temperature in °C, or `missing` on failure."""
function globe_temperature(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_pressure_hpa(
        globe_temperature,
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg,
    )
    result = _liljegren_scalar(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg;
        pressure_hpa, direct_fraction, config, mode = _ValueMode(),
    )
    return result.globe_temperature_c
end

"""Return scalar Liljegren natural wet-bulb temperature in °C, or `missing` on failure."""
function natural_wet_bulb_temperature(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_pressure_hpa(
        natural_wet_bulb_temperature,
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg,
    )
    result = _liljegren_scalar(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2,
        time, longitude_deg, latitude_deg;
        pressure_hpa, direct_fraction, config, mode = _ValueMode(),
    )
    return result.natural_wet_bulb_c
end
