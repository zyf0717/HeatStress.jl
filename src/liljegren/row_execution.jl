function _solve_prepared_liljegren(
    prepared::_PreparedMeteorology{T},
    config::LiljegrenConfig{T},
) where {T<:AbstractFloat}
    vapour_pressure_hpa = _saturation_vapour_pressure_hpa_unchecked(prepared.dew_point_c)
    atmospheric_emissivity = _atmospheric_emissivity(vapour_pressure_hpa)
    effective_wind_speed_m_s = _effective_wind_speed_m_s(
        prepared.wind_speed_m_s,
        config.minimum_wind_speed_m_s,
    )
    air_density = _air_density(prepared.air_temperature_k, prepared.pressure_hpa)
    air_viscosity = _air_viscosity(prepared.air_temperature_k)
    mass_transfer_ratio = _diffusivity_coefficient(
        prepared.air_temperature_k,
        prepared.pressure_hpa,
        air_density,
        air_viscosity,
    )
    all(isfinite, (
        vapour_pressure_hpa,
        atmospheric_emissivity,
        effective_wind_speed_m_s,
        air_density,
        air_viscosity,
        mass_transfer_ratio,
    )) || return _InputPreparationFailure(InvalidDomain)

    globe = _solve_globe_balance_data(
        _globe_balance(prepared, atmospheric_emissivity, effective_wind_speed_m_s, config),
        config.solver,
    )
    natural_wet_bulb = _solve_natural_wet_bulb_balance_data(
        _wet_bulb_balance(
            prepared,
            vapour_pressure_hpa,
            atmospheric_emissivity,
            effective_wind_speed_m_s,
            air_density,
            air_viscosity,
            mass_transfer_ratio,
            config,
        ),
        prepared.dew_point_k,
        config.solver,
    )
    return _ScalarSolveData{T}(globe, natural_wet_bulb)
end

function _liljegren_row_from_zenith(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    solar_zenith_rad::Real,
    pressure_hpa::Union{Missing,Real},
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig{T},
    mode::_ScalarResultMode,
) where {T<:AbstractFloat}
    basic = _normalize_basic_meteorology(
        air_temperature_c,
        dew_point_c,
        wind_speed_m_s,
        solar_radiation_w_m2;
        pressure_hpa,
        direct_fraction,
        config,
        float_type = T,
    )
    basic isa _InputPreparationFailure && return _input_failure_result(T, mode, basic.status, config)
    prepared = _apply_solar_policy(basic, solar_zenith_rad)
    prepared isa _InputPreparationFailure && return _input_failure_result(T, mode, prepared.status, config)
    data = _solve_prepared_liljegren(prepared, config)
    data isa _InputPreparationFailure && return _input_failure_result(T, mode, data.status, config)
    return _materialize_result(prepared, data, config, mode)
end

function _liljegren_row_from_time(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real,
    pressure_hpa::Union{Missing,Real},
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig{T},
    mode::_ScalarResultMode,
) where {T<:AbstractFloat}
    ismissing(time) && return _input_failure_result(T, mode, MissingTime, config)
    isfinite(longitude_deg) && -180 <= longitude_deg <= 180 &&
        isfinite(latitude_deg) && -90 <= latitude_deg <= 90 ||
        return _input_failure_result(T, mode, InvalidDomain, config)
    solar_zenith_rad = convert(T, deg2rad(solar_zenith(time, longitude_deg, latitude_deg)))
    return _liljegren_row_from_zenith(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2, solar_zenith_rad,
        pressure_hpa, direct_fraction, config, mode,
    )
end

function _liljegren_row_from_cached_zenith(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real,
    solar_zenith_deg::Real,
    pressure_hpa::Union{Missing,Real},
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig{T},
    mode::_ScalarResultMode,
) where {T<:AbstractFloat}
    ismissing(time) && return _input_failure_result(T, mode, MissingTime, config)
    isfinite(longitude_deg) && -180 <= longitude_deg <= 180 &&
        isfinite(latitude_deg) && -90 <= latitude_deg <= 90 ||
        return _input_failure_result(T, mode, InvalidDomain, config)
    solar_zenith_rad = convert(T, deg2rad(solar_zenith_deg))
    return _liljegren_row_from_zenith(
        air_temperature_c, dew_point_c, wind_speed_m_s, solar_radiation_w_m2, solar_zenith_rad,
        pressure_hpa, direct_fraction, config, mode,
    )
end
