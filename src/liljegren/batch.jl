@inline _at(value::Real, ::Int) = value
@inline _at(::Missing, ::Int) = missing
@inline _at(values::AbstractVector, row::Int) = @inbounds values[firstindex(values) + row - 1]

@inline _batch_value_type(::Type{Missing}) = Union{}
@inline _batch_value_type(::Type{Union{}}) = Union{}
@inline _batch_value_type(::Type{T}) where {T<:Real} = typeof(float(zero(T)))
@inline _batch_value_type(::Type{<:AbstractVector{T}}) where {T} =
    _batch_value_type(Base.nonmissingtype(T))

function _batch_float_type(inputs...; config::LiljegrenConfig)
    return promote_type(
        (_batch_value_type(typeof(input)) for input in inputs)...,
        typeof(config.dew_point_tolerance_c),
    )
end

function _batch_rows(primary::AbstractVector...)
    isempty(primary) && return 0
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
    value isa Missing && throw(ArgumentError("$name must be a non-missing Real scalar or vector"))
    value isa AbstractVector || throw(ArgumentError("$name must be a non-missing Real scalar or vector"))
    return _validate_numeric_vector(value, rows, name; allow_missing = false)
end

function _validate_optional_numeric_argument(value, rows::Int, name::Symbol)
    value isa Union{Missing,Real} && return nothing
    value isa AbstractVector || throw(ArgumentError("$name must be a Real or Missing scalar or vector"))
    return _validate_numeric_vector(value, rows, name; allow_missing = true)
end

function _validate_batch_inputs(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    radiation::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    pressure_hpa,
    direct_fraction,
)
    rows = _batch_rows(air, dew, wind, radiation, time)
    _validate_numeric_vector(air, rows, :air_temperature_c; allow_missing = true)
    _validate_numeric_vector(dew, rows, :dew_point_c; allow_missing = true)
    _validate_numeric_vector(wind, rows, :wind_speed_m_s; allow_missing = true)
    _validate_numeric_vector(radiation, rows, :solar_radiation_w_m2; allow_missing = true)
    _validate_time_vector(time, rows, :time)
    _validate_location_argument(longitude, rows, :longitude_deg)
    _validate_location_argument(latitude, rows, :latitude_deg)
    _validate_optional_numeric_argument(pressure_hpa, rows, :pressure_hpa)
    _validate_optional_numeric_argument(direct_fraction, rows, :direct_fraction)
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
    radiation::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    pressure_hpa,
    direct_fraction,
    config::LiljegrenConfig,
)
    rows = _validate_batch_inputs(
        air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction,
    )
    T = _batch_float_type(
        air, dew, wind, radiation, longitude, latitude, pressure_hpa, direct_fraction;
        config,
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
    radiation::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    pressure_hpa,
    direct_fraction,
    config::LiljegrenConfig{T},
    threaded::Bool,
) where {T<:AbstractFloat}
    function solve_row(row)
        values = _liljegren_row_from_time(
            _at(air, row), _at(dew, row), _at(wind, row), _at(radiation, row), _at(time, row),
            _at(longitude, row), _at(latitude, row), _at(pressure_hpa, row),
            _at(direct_fraction, row), config, _ValueMode(),
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
    liljegren_wbgt!(wbgt_out, natural_wet_bulb_out, globe_temperature_out,
                    air_temperature_c, dew_point_c, wind_speed_m_s,
                    solar_radiation_w_m2, time, longitude_deg, latitude_deg;
                    pressure_hpa=1010, direct_fraction, config=LiljegrenConfig(),
                    threaded=false)

Mutate preallocated WBGT/component outputs (°C) for ordinally aligned primary
`AbstractVector` inputs. Meteorology, pressure and direct fraction may permit
`missing`; time accepts `DateTime`, `ZonedDateTime` or `missing`; longitude and
latitude are required non-missing real scalars or vectors. `DateTime` is UTC
and `ZonedDateTime` is converted to its UTC instant. Outputs may have different
axes, but must have equal lengths and accept `missing` and the promoted float
type. All invalid inputs, output types and aliases are rejected before mutation.
`threaded=true` uses available Julia threads; no processes are created.
"""
function liljegren_wbgt!(
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    radiation::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction,
    config::LiljegrenConfig = LiljegrenConfig(),
    threaded::Bool = false,
)
    rows, T, typed_config = _prepare_batch_inputs(
        air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config,
    )
    _validate_batch_outputs(rows, T, wbgt_out, wet_out, globe_out)
    _validate_batch_aliases(
        (wbgt_out, wet_out, globe_out),
        air, dew, wind, radiation, time, longitude, latitude, pressure_hpa, direct_fraction,
    )
    _execute_value_batch!(
        rows, wbgt_out, wet_out, globe_out, air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config = typed_config, threaded,
    )
    return WBGTBatchResult{T}(wbgt_out, wet_out, globe_out)
end

"""
    liljegren_wbgt_batch(air_temperature_c, dew_point_c, wind_speed_m_s,
                         solar_radiation_w_m2, time, longitude_deg, latitude_deg;
                         pressure_hpa=1010, direct_fraction,
                         config=LiljegrenConfig(), threaded=false)

Return ordinary 1-based `Vector{Union{Missing,T}}` WBGT/component outputs (°C)
for ordinally aligned `AbstractVector` inputs. Input, coordinate, time,
missingness and threading semantics match [`liljegren_wbgt!`](@ref). Value-only
v0.1 emits no aggregate warnings; use [`diagnose_liljegren_batch`](@ref) for
row-level input and solver diagnostics.
"""
function liljegren_wbgt_batch(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    radiation::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction,
    config::LiljegrenConfig = LiljegrenConfig(),
    threaded::Bool = false,
)
    rows, T, typed_config = _prepare_batch_inputs(
        air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config,
    )
    wbgt = Vector{Union{Missing,T}}(undef, rows)
    wet = Vector{Union{Missing,T}}(undef, rows)
    globe = Vector{Union{Missing,T}}(undef, rows)
    _execute_value_batch!(
        rows, wbgt, wet, globe, air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config = typed_config, threaded,
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

function _store_component!(out::SolverDiagnosticsBatch, row::Int, value::SolverDiagnostics)
    for field in fieldnames(SolverDiagnosticsBatch)
        field === :converged && (out.converged[row] = value.converged; continue)
        field === :reason && (out.reason[row] = value.reason; continue)
        getproperty(out, field)[row] = getproperty(value, field)
    end
    return nothing
end

"""
    diagnose_liljegren_batch(air_temperature_c, dew_point_c, wind_speed_m_s,
                             solar_radiation_w_m2, time, longitude_deg, latitude_deg;
                             pressure_hpa=1010, direct_fraction,
                             config=LiljegrenConfig(), threaded=false)

Return a structure-of-arrays `DiagnosticWBGTBatchResult` for ordinally aligned
batch inputs. Its result components are °C; per-row flags and component solver
fields preserve scalar diagnostics. `threaded` records whether parallel
execution was requested and `threads_available` is `Threads.nthreads()`, not a
count of participating threads. Input, coordinate and time semantics match
[`liljegren_wbgt!`](@ref).
"""
function diagnose_liljegren_batch(
    air::AbstractVector,
    dew::AbstractVector,
    wind::AbstractVector,
    radiation::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    direct_fraction,
    config::LiljegrenConfig = LiljegrenConfig(),
    threaded::Bool = false,
)
    rows, T, typed_config = _prepare_batch_inputs(
        air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config,
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
    globe_diagnostics, wet_diagnostics = _diagnostic_arrays(T, rows)
    function diagnose_row(row)
        diagnostic = _liljegren_row_from_time(
            _at(air, row), _at(dew, row), _at(wind, row), _at(radiation, row),
            _at(time, row), _at(longitude, row), _at(latitude, row), _at(pressure_hpa, row),
            _at(direct_fraction, row), typed_config, _DiagnosticMode(),
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
        radiation_clamped, mismatch, clipped, globe_diagnostics, wet_diagnostics,
        threaded, Threads.nthreads(), rows,
    )
end
