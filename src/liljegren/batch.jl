@inline _at(value::Real, ::Int) = value
@inline _at(::Missing, ::Int) = missing
@inline _at(values::AbstractVector, row::Int) = @inbounds values[firstindex(values) + row - 1]

@inline _batch_value_type(::Type{Missing}) = Union{}
@inline _batch_value_type(::Type{T}) where {T<:Real} = typeof(float(zero(T)))
@inline _batch_value_type(::Type{<:AbstractVector{T}}) where {T} = _batch_value_type(Base.nonmissingtype(T))

function _batch_float_type(inputs...; config::LiljegrenConfig)
    return promote_type((_batch_value_type(typeof(input)) for input in inputs)...,
                        typeof(config.dew_point_tolerance_c))
end

function _batch_rows(primary::AbstractVector...)
    isempty(primary) && return 0
    rows = length(first(primary))
    all(length(input) == rows for input in primary) ||
        throw(ArgumentError("primary meteorology and time arrays must have identical lengths"))
    return rows
end

function _validate_batch_argument(value, rows::Int, name::Symbol)
    value isa Union{Missing,Real} && return nothing
    value isa AbstractVector || throw(ArgumentError("$name must be a scalar or AbstractVector"))
    length(value) == rows || throw(ArgumentError("$name vector must have $rows elements"))
    return nothing
end

function _validate_batch_outputs(rows::Int, T::Type{<:AbstractFloat}, outputs::AbstractVector...)
    for output in outputs
        length(output) == rows || throw(ArgumentError("output vectors must have $rows elements"))
        Missing <: eltype(output) && T <: eltype(output) ||
            throw(ArgumentError("output element type must accept Missing and $T"))
    end
    return nothing
end

function _batch_loop!(
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
    config::LiljegrenConfig,
    threaded::Bool,
)
    rows = _batch_rows(air, dew, wind, radiation, time)
    _validate_batch_argument(longitude, rows, :longitude_deg)
    _validate_batch_argument(latitude, rows, :latitude_deg)
    _validate_batch_argument(pressure_hpa, rows, :pressure_hpa)
    _validate_batch_argument(direct_fraction, rows, :direct_fraction)
    T = _batch_float_type(air, dew, wind, radiation, longitude, latitude, pressure_hpa, direct_fraction; config)
    _validate_batch_outputs(rows, T, wbgt_out, wet_out, globe_out)
    function solve_row(row)
        result = liljegren_wbgt(
            _at(air, row), _at(dew, row), _at(wind, row), _at(radiation, row), _at(time, row),
            _at(longitude, row), _at(latitude, row);
            pressure_hpa = _at(pressure_hpa, row), direct_fraction = _at(direct_fraction, row), config,
        )
        index = firstindex(wbgt_out) + row - 1
        @inbounds wbgt_out[index] = result.wbgt_c
        @inbounds wet_out[firstindex(wet_out) + row - 1] = result.natural_wet_bulb_c
        @inbounds globe_out[firstindex(globe_out) + row - 1] = result.globe_temperature_c
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

function liljegren_wbgt!(wbgt_out::AbstractVector, wet_out::AbstractVector, globe_out::AbstractVector,
    air::AbstractVector, dew::AbstractVector, wind::AbstractVector, radiation::AbstractVector,
    time::AbstractVector, longitude, latitude;
    pressure_hpa = DEFAULT_PRESSURE_HPA, direct_fraction, config::LiljegrenConfig = LiljegrenConfig(), threaded::Bool = false)
    _batch_loop!(wbgt_out, wet_out, globe_out, air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config, threaded)
    return WBGTBatchResult(wbgt_out, wet_out, globe_out)
end

function liljegren_wbgt_batch(air::AbstractVector, dew::AbstractVector, wind::AbstractVector,
    radiation::AbstractVector, time::AbstractVector, longitude, latitude;
    pressure_hpa = DEFAULT_PRESSURE_HPA, direct_fraction, config::LiljegrenConfig = LiljegrenConfig(), threaded::Bool = false)
    rows = _batch_rows(air, dew, wind, radiation, time)
    _validate_batch_argument(longitude, rows, :longitude_deg)
    _validate_batch_argument(latitude, rows, :latitude_deg)
    _validate_batch_argument(pressure_hpa, rows, :pressure_hpa)
    _validate_batch_argument(direct_fraction, rows, :direct_fraction)
    T = _batch_float_type(air, dew, wind, radiation, longitude, latitude, pressure_hpa, direct_fraction; config)
    wbgt = Vector{Union{Missing,T}}(undef, rows)
    wet = Vector{Union{Missing,T}}(undef, rows)
    globe = Vector{Union{Missing,T}}(undef, rows)
    return liljegren_wbgt!(wbgt, wet, globe, air, dew, wind, radiation, time, longitude, latitude;
        pressure_hpa, direct_fraction, config, threaded)
end

function _diagnostic_arrays(::Type{T}, rows::Int) where {T<:AbstractFloat}
    missing_values() = fill!(Vector{Union{Missing,T}}(undef, rows), missing)
    component() = SolverDiagnosticsBatch{T}(falses(rows), fill(NotAttempted, rows), missing_values(), missing_values(), missing_values(), zeros(Int, rows), zeros(Int, rows), missing_values(), missing_values(), missing_values(), missing_values(), missing_values(), missing_values())
    return component(), component()
end

function _store_component!(out::SolverDiagnosticsBatch, row::Int, value::SolverDiagnostics)
    for field in fieldnames(SolverDiagnosticsBatch)
        field === :converged && (out.converged[row] = value.converged; continue)
        field === :reason && (out.reason[row] = value.reason; continue)
        getproperty(out, field)[row] = getproperty(value, field)
    end
end

function diagnose_liljegren_batch(air::AbstractVector, dew::AbstractVector, wind::AbstractVector,
    radiation::AbstractVector, time::AbstractVector, longitude, latitude;
    pressure_hpa = DEFAULT_PRESSURE_HPA, direct_fraction, config::LiljegrenConfig = LiljegrenConfig(), threaded::Bool = false)
    rows = _batch_rows(air, dew, wind, radiation, time)
    T = _batch_float_type(air, dew, wind, radiation, longitude, latitude, pressure_hpa, direct_fraction; config)
    wbgt = Vector{Union{Missing,T}}(undef, rows); wet = similar(wbgt); globe = similar(wbgt)
    status = Vector{InputStatus}(undef, rows); dew_adjusted = falses(rows); wind_clamped = falses(rows); radiation_clamped = falses(rows); mismatch = falses(rows); clipped = falses(rows)
    globe_diagnostics, wet_diagnostics = _diagnostic_arrays(T, rows)
    function diagnose_row(row)
        diagnostic = diagnose_liljegren(_at(air,row), _at(dew,row), _at(wind,row), _at(radiation,row), _at(time,row), _at(longitude,row), _at(latitude,row); pressure_hpa=_at(pressure_hpa,row), direct_fraction=_at(direct_fraction,row), config)
        wbgt[row] = diagnostic.result.wbgt_c; wet[row] = diagnostic.result.natural_wet_bulb_c; globe[row] = diagnostic.result.globe_temperature_c
        status[row] = diagnostic.input_status; dew_adjusted[row] = diagnostic.dew_point_adjusted; wind_clamped[row] = diagnostic.wind_speed_clamped; radiation_clamped[row] = diagnostic.solar_radiation_clamped; mismatch[row] = diagnostic.solar_geometry_mismatch; clipped[row] = diagnostic.direct_solar_clipped
        _store_component!(globe_diagnostics,row,diagnostic.globe); _store_component!(wet_diagnostics,row,diagnostic.natural_wet_bulb)
    end
    if threaded && rows > 0
        Threads.@threads for row in 1:rows; diagnose_row(row); end
    else
        for row in 1:rows; diagnose_row(row); end
    end
    return DiagnosticWBGTBatchResult{T}(WBGTBatchResult(wbgt,wet,globe),status,dew_adjusted,wind_clamped,radiation_clamped,mismatch,clipped,globe_diagnostics,wet_diagnostics,threaded,Threads.nthreads(),rows)
end
