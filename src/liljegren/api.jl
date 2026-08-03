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
        convert(T, config.irradiance_closure_atol_w_m2),
        convert(T, config.irradiance_closure_kt_tolerance),
    )
end

@inline _scalar_float_type(::Type{Nothing}) = Union{}
@inline _scalar_float_type(::Type{Missing}) = Union{}
@inline _scalar_float_type(::Type{T}) where {T<:Real} = typeof(float(zero(T)))

@inline _partition_float_type(::LiljegrenClearnessFraction) = Union{}
@inline _partition_float_type(policy::FixedDirectFraction{<:Real}) =
    _scalar_float_type(typeof(policy.value))

@inline _wind_height_float_type(::NoWindHeightAdjustment, inputs...) = Union{}
@inline function _wind_height_float_type(::LiljegrenStabilityPowerLaw, inputs...)
    return promote_type((_scalar_float_type(typeof(input)) for input in inputs)...)
end

@noinline function _reject_public_argument(function_object, arguments...)
    throw(MethodError(function_object, arguments))
end

function _validate_scalar_partition(policy::RadiationPartitionPolicy)
    policy isa LiljegrenClearnessFraction && return policy
    policy isa FixedDirectFraction{<:Real} && return policy
    throw(ArgumentError("scalar partition must contain one fixed Real value or use LiljegrenClearnessFraction()"))
end

@inline function _scalar_input_type(
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    ghi_w_m2,
    dni_w_m2,
    dhi_w_m2,
    pressure_hpa,
    longitude_deg,
    latitude_deg,
    partition::RadiationPartitionPolicy,
    wind_height_m,
    wind_height_policy::WindHeightPolicy,
    vertical_temperature_difference_c,
    config::LiljegrenConfig,
)
    return promote_type(
        _scalar_float_type(typeof(air_temperature_c)),
        _scalar_float_type(typeof(dew_point_c)),
        _scalar_float_type(typeof(wind_speed_m_s)),
        _scalar_float_type(typeof(ghi_w_m2)),
        _scalar_float_type(typeof(dni_w_m2)),
        _scalar_float_type(typeof(dhi_w_m2)),
        _scalar_float_type(typeof(pressure_hpa)),
        _scalar_float_type(typeof(longitude_deg)),
        _scalar_float_type(typeof(latitude_deg)),
        _partition_float_type(partition),
        _wind_height_float_type(
            wind_height_policy,
            wind_height_m,
            vertical_temperature_difference_c,
        ),
        _scalar_float_type(typeof(config.dew_point_tolerance_c)),
    )
end

function _liljegren_scalar(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2::Union{Nothing,Missing,Real} = nothing,
    dni_w_m2::Union{Nothing,Missing,Real} = nothing,
    dhi_w_m2::Union{Nothing,Missing,Real} = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa::Union{Missing,Real} = DEFAULT_PRESSURE_HPA,
    wind_height_m::Union{Missing,Real} = 2.0,
    wind_height_policy::WindHeightPolicy = NoWindHeightAdjustment(),
    terrain::WindTerrain = Rural(),
    stability_class::Union{Nothing,PasquillStabilityClass} = nothing,
    vertical_temperature_difference_c::Union{Nothing,Missing,Real} = nothing,
    config::LiljegrenConfig = LiljegrenConfig(),
    mode::_ScalarResultMode = _DiagnosticMode(),
)
    partition = _validate_scalar_partition(partition)
    _validate_wind_height_policy_inputs(
        wind_height_policy,
        stability_class,
        vertical_temperature_difference_c,
    )
    input_type = _scalar_input_type(
        air_temperature_c, dew_point_c, wind_speed_m_s,
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa,
        longitude_deg, latitude_deg, partition,
        wind_height_m, wind_height_policy, vertical_temperature_difference_c,
        config,
    )
    typed_config = _config_as_type(input_type, config)
    row_result = _liljegren_row_from_time(
        air_temperature_c, dew_point_c, wind_speed_m_s,
        time, longitude_deg, latitude_deg, pressure_hpa,
        ghi_w_m2, dni_w_m2, dhi_w_m2, partition, typed_config, mode,
        wind_height_m, wind_height_policy, terrain, stability_class,
        vertical_temperature_difference_c,
    )
    return _scalar_public_result(input_type, row_result, mode)
end

"""
    diagnose_liljegren(air_temperature_c, dew_point_c, wind_speed_m_s,
                       time, longitude_deg, latitude_deg;
                       ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                       partition=FixedDirectFraction(0.8),
                       pressure_hpa=1010, config=LiljegrenConfig())

Return a diagnostic scalar Liljegren result. Irradiance components are W/m²:
GHI and DHI are horizontal, while DNI is normal to the solar beam. With no
components supplied, clear-sky GHI is estimated from time and location.
"""
function diagnose_liljegren(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2::Union{Nothing,Missing,Real} = nothing,
    dni_w_m2::Union{Nothing,Missing,Real} = nothing,
    dhi_w_m2::Union{Nothing,Missing,Real} = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    wind_height_m = 2.0,
    wind_height_policy::WindHeightPolicy = NoWindHeightAdjustment(),
    terrain::WindTerrain = Rural(),
    stability_class = nothing,
    vertical_temperature_difference_c = nothing,
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_argument(
        diagnose_liljegren,
        air_temperature_c, dew_point_c, wind_speed_m_s, time,
        longitude_deg, latitude_deg,
    )
    return _liljegren_scalar(
        air_temperature_c, dew_point_c, wind_speed_m_s,
        time, longitude_deg, latitude_deg;
        ghi_w_m2, dni_w_m2, dhi_w_m2, partition,
        pressure_hpa, wind_height_m, wind_height_policy, terrain,
        stability_class, vertical_temperature_difference_c,
        config, mode = _DiagnosticMode(),
    )
end

"""Return the scalar Liljegren WBGT result (°C components and WBGT)."""
function liljegren_wbgt(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2::Union{Nothing,Missing,Real} = nothing,
    dni_w_m2::Union{Nothing,Missing,Real} = nothing,
    dhi_w_m2::Union{Nothing,Missing,Real} = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    wind_height_m = 2.0,
    wind_height_policy::WindHeightPolicy = NoWindHeightAdjustment(),
    terrain::WindTerrain = Rural(),
    stability_class = nothing,
    vertical_temperature_difference_c = nothing,
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_argument(
        liljegren_wbgt,
        air_temperature_c, dew_point_c, wind_speed_m_s, time,
        longitude_deg, latitude_deg,
    )
    return _liljegren_scalar(
        air_temperature_c, dew_point_c, wind_speed_m_s,
        time, longitude_deg, latitude_deg;
        ghi_w_m2, dni_w_m2, dhi_w_m2, partition,
        pressure_hpa, wind_height_m, wind_height_policy, terrain,
        stability_class, vertical_temperature_difference_c,
        config, mode = _ValueMode(),
    )
end

"""Return scalar Liljegren globe temperature in °C, or `missing` on failure."""
function globe_temperature(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2::Union{Nothing,Missing,Real} = nothing,
    dni_w_m2::Union{Nothing,Missing,Real} = nothing,
    dhi_w_m2::Union{Nothing,Missing,Real} = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    wind_height_m = 2.0,
    wind_height_policy::WindHeightPolicy = NoWindHeightAdjustment(),
    terrain::WindTerrain = Rural(),
    stability_class = nothing,
    vertical_temperature_difference_c = nothing,
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_argument(
        globe_temperature,
        air_temperature_c, dew_point_c, wind_speed_m_s, time,
        longitude_deg, latitude_deg,
    )
    return liljegren_wbgt(
        air_temperature_c, dew_point_c, wind_speed_m_s,
        time, longitude_deg, latitude_deg;
        ghi_w_m2, dni_w_m2, dhi_w_m2, partition, pressure_hpa,
        wind_height_m, wind_height_policy, terrain, stability_class,
        vertical_temperature_difference_c, config,
    ).globe_temperature_c
end

"""Return scalar Liljegren natural wet-bulb temperature in °C, or `missing`."""
function natural_wet_bulb_temperature(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    time::Union{Missing,DateTime,ZonedDateTime},
    longitude_deg::Real,
    latitude_deg::Real;
    ghi_w_m2::Union{Nothing,Missing,Real} = nothing,
    dni_w_m2::Union{Nothing,Missing,Real} = nothing,
    dhi_w_m2::Union{Nothing,Missing,Real} = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    wind_height_m = 2.0,
    wind_height_policy::WindHeightPolicy = NoWindHeightAdjustment(),
    terrain::WindTerrain = Rural(),
    stability_class = nothing,
    vertical_temperature_difference_c = nothing,
    config::LiljegrenConfig = LiljegrenConfig(),
)
    pressure_hpa isa Union{Missing,Real} || _reject_public_argument(
        natural_wet_bulb_temperature,
        air_temperature_c, dew_point_c, wind_speed_m_s, time,
        longitude_deg, latitude_deg,
    )
    return liljegren_wbgt(
        air_temperature_c, dew_point_c, wind_speed_m_s,
        time, longitude_deg, latitude_deg;
        ghi_w_m2, dni_w_m2, dhi_w_m2, partition, pressure_hpa,
        wind_height_m, wind_height_policy, terrain, stability_class,
        vertical_temperature_difference_c, config,
    ).natural_wet_bulb_c
end
