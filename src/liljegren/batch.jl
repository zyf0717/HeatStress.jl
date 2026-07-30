@inline _at(::Nothing, ::Int) = nothing
@inline _at(value::Real, ::Int) = value
@inline _at(::Missing, ::Int) = missing
@inline _at(values::AbstractVector, row::Int) =
    @inbounds values[firstindex(values) + row - 1]

@inline _batch_value_type(::Type{Nothing}) = Union{}
@inline _batch_value_type(::Type{Missing}) = Union{}
@inline _batch_value_type(::Type{Union{}}) = Union{}
@inline _batch_value_type(::Type{T}) where {T<:Real} = typeof(float(zero(T)))
@inline _batch_value_type(::Type{<:AbstractVector{T}}) where {T} =
    _batch_value_type(Base.nonmissingtype(T))

@inline _partition_values(::LiljegrenClearnessFraction) = nothing
@inline _partition_values(policy::FixedDirectFraction) = policy.value
@inline _partition_at(policy::LiljegrenClearnessFraction, ::Int) = policy
@inline function _partition_at(policy::FixedDirectFraction, row::Int)
    value = _at(policy.value, row)
    return FixedDirectFraction{typeof(value)}(value)
end

function _batch_float_type(inputs...; partition::RadiationPartitionPolicy, config::LiljegrenConfig)
    return promote_type(
        (_batch_value_type(typeof(input)) for input in inputs)...,
        _batch_value_type(typeof(_partition_values(partition))),
        typeof(config.dew_point_tolerance_c),
    )
end

function _batch_rows(primary::AbstractVector...)
    rows = length(first(primary))
    all(length(input) == rows for input in primary) ||
        throw(ArgumentError("primary meteorology and time arrays must have identical lengths"))
    return rows
end

function _validate_numeric_vector(
    value::AbstractVector,
    rows::Int,
    name::Symbol;
    allow_missing::Bool,
)
    length(value) == rows || throw(ArgumentError("$name vector must have $rows elements"))
    element_type = eltype(value)
    if element_type === Missing
        allow_missing || throw(ArgumentError("$name must not permit Missing"))
        return nothing
    end
    nonmissing_type = Base.nonmissingtype(element_type)
    isconcretetype(nonmissing_type) && nonmissing_type <: Real ||
        throw(ArgumentError("$name vector must have a concrete Real element type$(allow_missing ? " optionally unioned with Missing" : "")"))
    allow_missing || !(Missing <: element_type) ||
        throw(ArgumentError("$name must not permit Missing"))
    return nothing
end

function _validate_time_vector(value::AbstractVector, rows::Int, name::Symbol)
    length(value) == rows || throw(ArgumentError("$name vector must have $rows elements"))
    eltype(value) <: Union{Missing,DateTime,ZonedDateTime} ||
        throw(ArgumentError("$name vector must contain DateTime, ZonedDateTime, or Missing values"))
    return nothing
end

function _validate_location_argument(value, rows::Int, name::Symbol)
    value isa Real && return nothing
    value isa AbstractVector ||
        throw(ArgumentError("$name must be a non-missing Real scalar or vector"))
    return _validate_numeric_vector(value, rows, name; allow_missing = false)
end

function _validate_optional_numeric_argument(value, rows::Int, name::Symbol)
    value isa Union{Missing,Real} && return nothing
    value isa AbstractVector ||
        throw(ArgumentError("$name must be a Real or Missing scalar or vector"))
    return _validate_numeric_vector(value, rows, name; allow_missing = true)
end

function _validate_irradiance_argument(value, rows::Int, name::Symbol)
    value isa Union{Nothing,Missing,Real} && return nothing
    value isa AbstractVector ||
        throw(ArgumentError("$name must be nothing, a Real/Missing scalar, or a vector"))
    return _validate_numeric_vector(value, rows, name; allow_missing = true)
end

function _validate_partition(policy::RadiationPartitionPolicy, rows::Int)
    policy isa LiljegrenClearnessFraction && return nothing
    values = policy.value
    values isa Real && return nothing
    values isa AbstractVector ||
        throw(ArgumentError("fixed direct fraction must be a Real scalar or vector"))
    _validate_numeric_vector(values, rows, :direct_fraction; allow_missing = false)
    all(value -> isfinite(value) && 0 <= value <= 1, values) ||
        throw(ArgumentError("fixed direct-fraction values must be finite and in [0, 1]"))
    return nothing
end

function _validate_batch_inputs(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    dni_w_m2,
    dhi_w_m2,
    pressure_hpa,
    partition,
)
    rows = _batch_rows(air, dew, wind, time)
    _validate_numeric_vector(air, rows, :air_temperature_c; allow_missing = true)
    _validate_numeric_vector(dew, rows, :dew_point_c; allow_missing = true)
    _validate_numeric_vector(wind, rows, :wind_speed_m_s; allow_missing = true)
    _validate_time_vector(time, rows, :time)
    _validate_location_argument(longitude, rows, :longitude_deg)
    _validate_location_argument(latitude, rows, :latitude_deg)
    _validate_irradiance_argument(ghi_w_m2, rows, :ghi_w_m2)
    _validate_irradiance_argument(dni_w_m2, rows, :dni_w_m2)
    _validate_irradiance_argument(dhi_w_m2, rows, :dhi_w_m2)
    _validate_optional_numeric_argument(pressure_hpa, rows, :pressure_hpa)
    _validate_partition(partition, rows)
    return rows
end

function _validate_batch_outputs(rows::Int, T::Type{<:AbstractFloat}, outputs::AbstractVector...)
    for output in outputs
        length(output) == rows ||
            throw(ArgumentError("output vectors must have $rows elements"))
        Missing <: eltype(output) && T <: eltype(output) ||
            throw(ArgumentError("output element type must accept Missing and $T"))
    end
    return nothing
end

function _validate_batch_aliases(outputs::Tuple, inputs...)
    for output_index in eachindex(outputs)
        for other_index in (output_index + 1):length(outputs)
            Base.mightalias(outputs[output_index], outputs[other_index]) &&
                throw(ArgumentError("batch output arrays must not alias one another"))
        end
        for input in inputs
            input isa AbstractVector && Base.mightalias(outputs[output_index], input) &&
                throw(ArgumentError("batch output arrays must not alias input arrays"))
        end
    end
    return nothing
end

function _prepare_batch_inputs(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    dni_w_m2,
    dhi_w_m2,
    pressure_hpa,
    partition::RadiationPartitionPolicy,
    config::LiljegrenConfig,
)
    rows = _validate_batch_inputs(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa, partition,
    )
    T = _batch_float_type(
        air, dew, wind, ghi_w_m2, dni_w_m2, dhi_w_m2,
        longitude, latitude, pressure_hpa;
        partition, config,
    )
    return rows, T, _config_as_type(T, config)
end

function _execute_value_batch!(
    rows::Int,
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    dni_w_m2,
    dhi_w_m2,
    pressure_hpa,
    partition,
    config::LiljegrenConfig{T},
    threaded::Bool,
) where {T<:AbstractFloat}
    function solve_row(row)
        values = _liljegren_row_from_time(
            _at(air, row), _at(dew, row), _at(wind, row), _at(time, row),
            _at(longitude, row), _at(latitude, row), _at(pressure_hpa, row),
            _at(ghi_w_m2, row), _at(dni_w_m2, row), _at(dhi_w_m2, row),
            _partition_at(partition, row), config, _ValueMode(),
        )
        @inbounds wbgt_out[firstindex(wbgt_out) + row - 1] =
            _component_or_missing(values.wbgt_c, values.wbgt_missing)
        @inbounds wet_out[firstindex(wet_out) + row - 1] =
            _component_or_missing(values.natural_wet_bulb_c, values.natural_wet_bulb_missing)
        @inbounds globe_out[firstindex(globe_out) + row - 1] =
            _component_or_missing(values.globe_temperature_c, values.globe_temperature_missing)
    end
    if threaded && rows > 0
        Threads.@threads for row in 1:rows
            solve_row(row)
        end
    else
        for row in 1:rows
            solve_row(row)
        end
    end
    return nothing
end

"""
    liljegren_wbgt!(outputs..., air, dew, wind, time, longitude, latitude;
                    ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                    partition=FixedDirectFraction(0.8), pressure_hpa=1010,
                    config=LiljegrenConfig(), threaded=false)

Mutate preallocated WBGT/component outputs for aligned primary arrays. Optional
irradiance components and fixed fractions may be shared scalars or aligned
vectors. Validation completes before any output is written.
"""
function liljegren_wbgt!(
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2 = nothing,
    dni_w_m2 = nothing,
    dhi_w_m2 = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    config::LiljegrenConfig = LiljegrenConfig(),
    threaded::Bool = false,
)
    rows, T, typed_config = _prepare_batch_inputs(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa, partition, config,
    )
    _validate_batch_outputs(rows, T, wbgt_out, wet_out, globe_out)
    _validate_batch_aliases(
        (wbgt_out, wet_out, globe_out),
        air, dew, wind, time, longitude, latitude, ghi_w_m2, dni_w_m2, dhi_w_m2,
        pressure_hpa, _partition_values(partition),
    )
    _execute_value_batch!(
        rows, wbgt_out, wet_out, globe_out, air, dew, wind, time, longitude, latitude;
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa, partition,
        config = typed_config, threaded,
    )
    return WBGTBatchResult{T}(wbgt_out, wet_out, globe_out)
end

"""
    liljegren_wbgt_batch(air, dew, wind, time, longitude, latitude;
                         ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                         partition=FixedDirectFraction(0.8),
                         pressure_hpa=1010, config=LiljegrenConfig(),
                         threaded=false)

Return aligned WBGT/component arrays. With no irradiance components, each
daytime row uses estimated clear-sky GHI.
"""
function liljegren_wbgt_batch(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2 = nothing,
    dni_w_m2 = nothing,
    dhi_w_m2 = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    config::LiljegrenConfig = LiljegrenConfig(),
    threaded::Bool = false,
)
    rows, T, typed_config = _prepare_batch_inputs(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa, partition, config,
    )
    wbgt = Vector{Union{Missing,T}}(undef, rows)
    wet = similar(wbgt)
    globe = similar(wbgt)
    _execute_value_batch!(
        rows, wbgt, wet, globe, air, dew, wind, time, longitude, latitude;
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa, partition,
        config = typed_config, threaded,
    )
    return WBGTBatchResult{T}(wbgt, wet, globe)
end

function _diagnostic_arrays(::Type{T}, rows::Int) where {T<:AbstractFloat}
    missing_values() = fill!(Vector{Union{Missing,T}}(undef, rows), missing)
    component() = SolverDiagnosticsBatch{T}(
        fill(false, rows), fill(NotAttempted, rows), missing_values(), missing_values(),
        missing_values(), zeros(Int, rows), zeros(Int, rows), missing_values(),
        missing_values(), missing_values(), missing_values(), missing_values(), missing_values(),
    )
    return component(), component()
end

function _irradiance_diagnostic_arrays(::Type{T}, rows::Int) where {T<:AbstractFloat}
    missing_values() = fill!(Vector{Union{Missing,T}}(undef, rows), missing)
    return IrradianceDiagnosticsBatch{T}(
        missing_values(), missing_values(), missing_values(), missing_values(), missing_values(),
        fill(false, rows), fill(false, rows), fill(false, rows),
        fill(false, rows), fill(false, rows), fill(false, rows),
        fill(false, rows), fill(false, rows), fill(false, rows),
        fill(false, rows), missing_values(), missing_values(), fill(false, rows),
        fill(:unknown, rows),
    )
end

function _store_component!(out::SolverDiagnosticsBatch, row::Int, value::SolverDiagnostics)
    @inbounds out.converged[row] = value.converged
    @inbounds out.reason[row] = value.reason
    @inbounds out.value_c[row] = value.value_c
    @inbounds out.candidate_c[row] = value.candidate_c
    @inbounds out.validation_residual_k[row] = value.validation_residual_k
    @inbounds out.evaluations[row] = value.evaluations
    @inbounds out.iterations[row] = value.iterations
    @inbounds out.initial_lower_k[row] = value.initial_lower_k
    @inbounds out.initial_upper_k[row] = value.initial_upper_k
    @inbounds out.final_lower_k[row] = value.final_lower_k
    @inbounds out.final_upper_k[row] = value.final_upper_k
    @inbounds out.lower_location_residual[row] = value.lower_location_residual
    @inbounds out.upper_location_residual[row] = value.upper_location_residual
    return nothing
end

function _store_irradiance!(
    out::IrradianceDiagnosticsBatch,
    row::Int,
    value::IrradianceDiagnostics,
)
    @inbounds out.ghi_w_m2[row] = value.ghi_w_m2
    @inbounds out.dni_w_m2[row] = value.dni_w_m2
    @inbounds out.dhi_w_m2[row] = value.dhi_w_m2
    @inbounds out.direct_fraction[row] = value.direct_fraction
    @inbounds out.clear_sky_ghi_w_m2[row] = value.clear_sky_ghi_w_m2
    @inbounds out.ghi_supplied[row] = value.ghi_supplied
    @inbounds out.dni_supplied[row] = value.dni_supplied
    @inbounds out.dhi_supplied[row] = value.dhi_supplied
    @inbounds out.ghi_estimated[row] = value.ghi_estimated
    @inbounds out.dni_estimated[row] = value.dni_estimated
    @inbounds out.dhi_estimated[row] = value.dhi_estimated
    @inbounds out.ghi_clamped[row] = value.ghi_clamped
    @inbounds out.dni_clamped[row] = value.dni_clamped
    @inbounds out.dhi_clamped[row] = value.dhi_clamped
    @inbounds out.derived_component_adjusted[row] = value.derived_component_adjusted
    @inbounds out.closure_residual_w_m2[row] = value.closure_residual_w_m2
    @inbounds out.closure_tolerance_w_m2[row] = value.closure_tolerance_w_m2
    @inbounds out.closure_mismatch[row] = value.closure_mismatch
    @inbounds out.partition_policy[row] = value.partition_policy
    return nothing
end

"""Return structure-of-arrays diagnostics for the component-aware batch API."""
function diagnose_liljegren_batch(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2 = nothing,
    dni_w_m2 = nothing,
    dhi_w_m2 = nothing,
    partition::RadiationPartitionPolicy = FixedDirectFraction(),
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    config::LiljegrenConfig = LiljegrenConfig(),
    threaded::Bool = false,
)
    rows, T, typed_config = _prepare_batch_inputs(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2, dni_w_m2, dhi_w_m2, pressure_hpa, partition, config,
    )
    wbgt = Vector{Union{Missing,T}}(undef, rows)
    wet = similar(wbgt)
    globe = similar(wbgt)
    status = Vector{InputStatus}(undef, rows)
    dew_adjusted = fill(false, rows)
    wind_clamped = fill(false, rows)
    radiation_clamped = fill(false, rows)
    mismatch = fill(false, rows)
    clipped = fill(false, rows)
    irradiance_diagnostics = _irradiance_diagnostic_arrays(T, rows)
    globe_diagnostics, wet_diagnostics = _diagnostic_arrays(T, rows)
    function diagnose_row(row)
        diagnostic = _liljegren_row_from_time(
            _at(air, row), _at(dew, row), _at(wind, row), _at(time, row),
            _at(longitude, row), _at(latitude, row), _at(pressure_hpa, row),
            _at(ghi_w_m2, row), _at(dni_w_m2, row), _at(dhi_w_m2, row),
            _partition_at(partition, row), typed_config, _DiagnosticMode(),
        )
        @inbounds wbgt[row] = diagnostic.result.wbgt_c
        @inbounds wet[row] = diagnostic.result.natural_wet_bulb_c
        @inbounds globe[row] = diagnostic.result.globe_temperature_c
        @inbounds status[row] = diagnostic.input_status
        @inbounds dew_adjusted[row] = diagnostic.dew_point_adjusted
        @inbounds wind_clamped[row] = diagnostic.wind_speed_clamped
        @inbounds radiation_clamped[row] = diagnostic.solar_radiation_clamped
        @inbounds mismatch[row] = diagnostic.solar_geometry_mismatch
        @inbounds clipped[row] = diagnostic.direct_solar_clipped
        _store_irradiance!(irradiance_diagnostics, row, diagnostic.irradiance)
        _store_component!(globe_diagnostics, row, diagnostic.globe)
        _store_component!(wet_diagnostics, row, diagnostic.natural_wet_bulb)
    end
    if threaded && rows > 0
        Threads.@threads for row in 1:rows
            diagnose_row(row)
        end
    else
        for row in 1:rows
            diagnose_row(row)
        end
    end
    return DiagnosticWBGTBatchResult{T}(
        WBGTBatchResult{T}(wbgt, wet, globe), status, dew_adjusted, wind_clamped,
        radiation_clamped, mismatch, clipped, irradiance_diagnostics,
        globe_diagnostics, wet_diagnostics, threaded, Threads.nthreads(), rows,
    )
end
