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

function _diagnose_prepared_liljegren(
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
    )) || return _input_failure_diagnostic(InvalidDomain, config)

    globe = _solve_globe_balance(
        _globe_balance(prepared, atmospheric_emissivity, effective_wind_speed_m_s, config),
        config.solver,
    )
    natural_wet_bulb = _solve_natural_wet_bulb_balance(
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

    wbgt_c = if !ismissing(globe.value_c) && !ismissing(natural_wet_bulb.value_c)
        convert(T, 0.7) * natural_wet_bulb.value_c +
        convert(T, 0.2) * globe.value_c +
        convert(T, 0.1) * prepared.air_temperature_c
    else
        missing
    end
    result = WBGTResult{T}(wbgt_c, natural_wet_bulb.value_c, globe.value_c)
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

function _diagnose_liljegren(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Missing,
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa::Union{Nothing,Missing,Real} = nothing,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
)
    return _input_failure_diagnostic(MissingTime, config)
end

function _diagnose_liljegren(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time::Union{DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa::Union{Nothing,Missing,Real} = nothing,
    direct_fraction::Union{Missing,Real},
    config::LiljegrenConfig = LiljegrenConfig(),
)
    if isnothing(pressure_hpa)
        input_type = _common_float_type(
            air_temperature_c,
            dew_point_c,
            wind_speed_m_s,
            solar_radiation_w_m2,
            direct_fraction,
            config.dew_point_tolerance_c,
        )
        pressure_hpa = convert(input_type, DEFAULT_PRESSURE_HPA)
    end
    isfinite(longitude_deg) && -180 <= longitude_deg <= 180 &&
        isfinite(latitude_deg) && -90 <= latitude_deg <= 90 ||
        return _input_failure_diagnostic(InvalidDomain, config)
    basic = _normalize_basic_meteorology(
        air_temperature_c,
        dew_point_c,
        wind_speed_m_s,
        solar_radiation_w_m2;
        pressure_hpa,
        direct_fraction,
        config,
    )
    basic isa _InputPreparationFailure && return _input_failure_diagnostic(basic.status, config)

    solar_zenith_rad = convert(typeof(basic.air_temperature_c), deg2rad(solar_zenith(time, longitude_deg, latitude_deg)))
    prepared = _apply_solar_policy(basic, solar_zenith_rad)
    prepared isa _InputPreparationFailure && return _input_failure_diagnostic(prepared.status, config)
    typed_config = _config_as_type(typeof(prepared.air_temperature_c), config)
    return _diagnose_prepared_liljegren(prepared, typed_config)
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
diagnose_liljegren(args...; kwargs...) = _diagnose_liljegren(args...; kwargs...)

"""Return the scalar Liljegren WBGT result (°C components and WBGT)."""
function liljegren_wbgt(args...; kwargs...)
    return diagnose_liljegren(args...; kwargs...).result
end

"""Return scalar Liljegren globe temperature in °C, or `missing` on failure."""
function globe_temperature(args...; kwargs...)
    return diagnose_liljegren(args...; kwargs...).result.globe_temperature_c
end

"""Return scalar Liljegren natural wet-bulb temperature in °C, or `missing` on failure."""
function natural_wet_bulb_temperature(args...; kwargs...)
    return diagnose_liljegren(args...; kwargs...).result.natural_wet_bulb_c
end
