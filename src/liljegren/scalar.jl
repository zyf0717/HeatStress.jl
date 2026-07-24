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

function _input_failure_diagnostic(status::InputStatus, config::LiljegrenConfig{T}) where {T<:AbstractFloat}
    diagnostics = _not_attempted_diagnostics(config.solver)
    return DiagnosticWBGTResult{T}(
        WBGTResult{T}(missing, missing, missing),
        status,
        false,
        false,
        false,
        false,
        false,
        diagnostics,
        diagnostics,
    )
end

@inline function _globe_balance(
    prepared::_PreparedMeteorology{T},
    atmospheric_emissivity::T,
    effective_wind_speed_m_s::T,
    config::LiljegrenConfig{T},
) where {T<:AbstractFloat}
    return GlobeBalance(
        prepared.air_temperature_k,
        prepared.pressure_hpa,
        effective_wind_speed_m_s,
        _globe_longwave_term(
            prepared.air_temperature_k,
            atmospheric_emissivity,
            convert(T, SURFACE_EMISSIVITY),
        ),
        _globe_solar_term(
            prepared.solar_radiation_w_m2,
            prepared.direct_fraction,
            prepared.solar_zenith_rad,
            config.surface_albedo,
            convert(T, GLOBE_ALBEDO),
            convert(T, GLOBE_EMISSIVITY),
        ),
        config.globe_diameter_m,
        convert(T, GLOBE_EMISSIVITY),
    )
end

@inline function _wet_bulb_balance(
    prepared::_PreparedMeteorology{T},
    vapour_pressure_hpa::T,
    atmospheric_emissivity::T,
    effective_wind_speed_m_s::T,
    air_density::T,
    air_viscosity::T,
    mass_transfer_ratio::T,
    config::LiljegrenConfig{T},
) where {T<:AbstractFloat}
    return WetBulbBalance(
        prepared.air_temperature_k,
        prepared.pressure_hpa,
        effective_wind_speed_m_s,
        vapour_pressure_hpa,
        air_density,
        air_viscosity,
        mass_transfer_ratio,
        _wet_bulb_longwave_term(
            prepared.air_temperature_k,
            atmospheric_emissivity,
            convert(T, WICK_EMISSIVITY),
            convert(T, SURFACE_EMISSIVITY),
        ),
        _wet_bulb_solar_term(
            prepared.solar_radiation_w_m2,
            prepared.direct_fraction,
            prepared.solar_zenith_rad,
            config.surface_albedo,
            convert(T, WICK_ALBEDO),
            convert(T, WICK_DIAMETER_M),
            convert(T, WICK_LENGTH_M),
        ),
        true,
        convert(T, WICK_DIAMETER_M),
        convert(T, WICK_EMISSIVITY),
    )
end

abstract type _ScalarResultMode end
struct _ValueMode <: _ScalarResultMode end
struct _DiagnosticMode <: _ScalarResultMode end

"""Shared component-solve state; diagnostics are materialized only on demand."""
struct _ScalarSolveData{T<:AbstractFloat}
    globe::_ValidatedComponentSolve{T}
    natural_wet_bulb::_ValidatedComponentSolve{T}
end

"""Internal isbits value-only row outcome; avoids public result materialisation in batch loops."""
struct _LiljegrenValue{T<:AbstractFloat}
    wbgt_c::T
    natural_wet_bulb_c::T
    globe_temperature_c::T
    wbgt_missing::Bool
    natural_wet_bulb_missing::Bool
    globe_temperature_missing::Bool
end

@inline _component_or_missing(value::T, is_missing::Bool) where {T<:AbstractFloat} =
    is_missing ? missing : value

@inline function _wbgt_values(
    air_temperature_c::T,
    globe_temperature_c::Union{Missing,T},
    natural_wet_bulb_c::Union{Missing,T},
) where {T<:AbstractFloat}
    wbgt_c = if !ismissing(globe_temperature_c) && !ismissing(natural_wet_bulb_c)
        convert(T, 0.7) * natural_wet_bulb_c +
        convert(T, 0.2) * globe_temperature_c +
        convert(T, 0.1) * air_temperature_c
    else
        missing
    end
    return _LiljegrenValue{T}(
        ismissing(wbgt_c) ? zero(T) : wbgt_c,
        ismissing(natural_wet_bulb_c) ? zero(T) : natural_wet_bulb_c,
        ismissing(globe_temperature_c) ? zero(T) : globe_temperature_c,
        ismissing(wbgt_c),
        ismissing(natural_wet_bulb_c),
        ismissing(globe_temperature_c),
    )
end

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

@inline function _materialize_result(
    prepared::_PreparedMeteorology{T},
    data::_ScalarSolveData{T},
    config::LiljegrenConfig{T},
    ::_ValueMode,
) where {T<:AbstractFloat}
    globe_temperature_c = _accepted_component_value(data.globe, config.solver)
    natural_wet_bulb_c = _accepted_component_value(data.natural_wet_bulb, config.solver)
    return _wbgt_values(prepared.air_temperature_c, globe_temperature_c, natural_wet_bulb_c)
end

@inline function _materialize_result(
    prepared::_PreparedMeteorology{T},
    data::_ScalarSolveData{T},
    config::LiljegrenConfig{T},
    ::_DiagnosticMode,
) where {T<:AbstractFloat}
    values = _materialize_result(prepared, data, config, _ValueMode())
    result = _scalar_public_result(T, values, _ValueMode())
    globe = _solver_diagnostics(
        data.globe.location,
        data.globe.validation_residual_k,
        config.solver,
        data.globe.validation_evaluations,
    )
    natural_wet_bulb = _solver_diagnostics(
        data.natural_wet_bulb.location,
        data.natural_wet_bulb.validation_residual_k,
        config.solver,
        data.natural_wet_bulb.validation_evaluations,
    )
    return DiagnosticWBGTResult{T}(
        result,
        InputAccepted,
        prepared.dew_point_adjusted,
        prepared.wind_speed_clamped,
        prepared.solar_radiation_clamped,
        prepared.solar_geometry_mismatch,
        prepared.direct_solar_clipped,
        globe,
        natural_wet_bulb,
    )
end

@inline _input_failure_result(::Type{T}, ::_ValueMode, ::InputStatus, ::LiljegrenConfig{T}) where {T<:AbstractFloat} =
    _LiljegrenValue{T}(zero(T), zero(T), zero(T), true, true, true)

@inline _input_failure_result(::Type{T}, ::_DiagnosticMode, status::InputStatus, config::LiljegrenConfig{T}) where {T<:AbstractFloat} =
    _input_failure_diagnostic(status, config)

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

@inline function _scalar_public_result(
    ::Type{T},
    values::_LiljegrenValue{T},
    ::_ValueMode,
) where {T<:AbstractFloat}
    return WBGTResult{T}(
        _component_or_missing(values.wbgt_c, values.wbgt_missing),
        _component_or_missing(values.natural_wet_bulb_c, values.natural_wet_bulb_missing),
        _component_or_missing(values.globe_temperature_c, values.globe_temperature_missing),
    )
end

@inline _scalar_public_result(::Type{T}, diagnostic::DiagnosticWBGTResult{T}, ::_DiagnosticMode) where {T<:AbstractFloat} = diagnostic

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
