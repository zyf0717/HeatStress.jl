# End-to-end acceptance benchmark for prepared batch solar geometry. Run this
# file against clean v0.1.0 and candidate environments with identical options.
using BenchmarkTools
using Dates
using HeatStress
using SHA
using Serialization
using TOML

const DEFAULT_ROW_COUNTS = (10_000, 100_000, 1_000_000)
const DEFAULT_SAMPLES = 3
const KEY_DISTRIBUTIONS = (:fixed, :grouped, :unique)

@inline _input_at(value::Real, ::Int) = value
@inline _input_at(values::AbstractVector, row::Int) = @inbounds values[row]

function _meteorology(rows::Int)
    air = Vector{Float64}(undef, rows)
    dew = Vector{Float64}(undef, rows)
    wind = Vector{Float64}(undef, rows)
    radiation = fill(750.0, rows)
    for row in eachindex(air)
        phase = 2π * mod(row - 1, 240) / 240
        air[row] = 28.0 + 4.0 * sin(phase)
        dew[row] = air[row] - (5.0 + cos(phase))
        wind[row] = 0.5 + 1.5 * abs(sin(phase))
    end
    return air, dew, wind, radiation
end

function _solar_keys(rows::Int, distribution::Symbol)
    base_time = DateTime(2024, 6, 21, 16)
    if distribution === :fixed
        times = [base_time + Minute(mod(row - 1, 240)) for row in 1:rows]
        return times, -74.0060, 40.7128
    elseif distribution === :grouped
        times = [base_time + Minute(mod(row - 1, 240)) for row in 1:rows]
        longitude = Vector{Float64}(undef, rows)
        latitude = Vector{Float64}(undef, rows)
        for row in eachindex(longitude)
            station = mod(row - 1, 8)
            longitude[row] = -123.0 + 18.0 * station
            latitude[row] = -35.0 + 10.0 * station
        end
        return times, longitude, latitude
    elseif distribution === :unique
        times = [base_time + Millisecond(row - 1) for row in 1:rows]
        scale = rows == 1 ? 0.0 : inv(rows - 1)
        longitude = [-179.0 + 358.0 * (row - 1) * scale for row in 1:rows]
        latitude = [-89.0 + 178.0 * (row - 1) * scale for row in 1:rows]
        return times, longitude, latitude
    end
    throw(ArgumentError("unknown key distribution: $distribution"))
end

function _inputs(rows::Int, distribution::Symbol)
    air, dew, wind, radiation = _meteorology(rows)
    time, longitude, latitude = _solar_keys(rows, distribution)
    return (; air, dew, wind, radiation, time, longitude, latitude)
end

function _outputs(rows::Int)
    values() = Vector{Union{Missing,Float64}}(undef, rows)
    return values(), values(), values()
end

function _scalar_reference(inputs)
    rows = length(inputs.air)
    wbgt, wet, globe = _outputs(rows)
    for row in 1:rows
        result = liljegren_wbgt(
            inputs.air[row],
            inputs.dew[row],
            inputs.wind[row],
            inputs.radiation[row],
            inputs.time[row],
            _input_at(inputs.longitude, row),
            _input_at(inputs.latitude, row);
            direct_fraction = 0.7,
        )
        wbgt[row] = result.wbgt_c
        wet[row] = result.natural_wet_bulb_c
        globe[row] = result.globe_temperature_c
    end
    return WBGTBatchResult{Float64}(wbgt, wet, globe)
end

function _scalar_solar_preparation(inputs)
    rows = length(inputs.time)
    result = Vector{Float64}(undef, rows)
    for row in 1:rows
        result[row] = solar_zenith(
            inputs.time[row],
            _input_at(inputs.longitude, row),
            _input_at(inputs.latitude, row),
        )
    end
    return result
end

function _prepared_solar_call(inputs)
    if isdefined(HeatStress, :_batch_solar_zenith)
        return () -> HeatStress._batch_solar_zenith(
            length(inputs.time), inputs.time, inputs.longitude, inputs.latitude,
        )
    end
    return () -> _scalar_solar_preparation(inputs)
end

function _assert_result_equal(actual::WBGTBatchResult, expected::WBGTBatchResult)
    isequal(actual.wbgt_c, expected.wbgt_c) || error("WBGT mismatch")
    isequal(actual.natural_wet_bulb_c, expected.natural_wet_bulb_c) ||
        error("natural wet-bulb mismatch")
    isequal(actual.globe_temperature_c, expected.globe_temperature_c) ||
        error("globe-temperature mismatch")
    return nothing
end

function _result_digest(result::WBGTBatchResult)
    io = IOBuffer()
    serialize(io, (
        result.wbgt_c,
        result.natural_wet_bulb_c,
        result.globe_temperature_c,
    ))
    return bytes2hex(sha256(take!(io)))
end

function _diagnostic_digest(diagnostic::DiagnosticWBGTBatchResult)
    io = IOBuffer()
    serialize(io, (
        diagnostic.result.wbgt_c,
        diagnostic.result.natural_wet_bulb_c,
        diagnostic.result.globe_temperature_c,
        diagnostic.input_status,
        diagnostic.dew_point_adjusted,
        diagnostic.wind_speed_clamped,
        diagnostic.solar_radiation_clamped,
        diagnostic.solar_geometry_mismatch,
        diagnostic.direct_solar_clipped,
    ))
    return bytes2hex(sha256(take!(io)))
end

function _missing_counts(result::WBGTBatchResult)
    return Dict(
        "wbgt" => count(ismissing, result.wbgt_c),
        "natural_wet_bulb" => count(ismissing, result.natural_wet_bulb_c),
        "globe_temperature" => count(ismissing, result.globe_temperature_c),
    )
end

function _status_counts(status::AbstractVector)
    counts = Dict{String,Int}()
    for value in status
        key = string(value)
        counts[key] = get(counts, key, 0) + 1
    end
    return counts
end

function _estimate(call, rows::Int, samples::Int)
    call()
    GC.gc()
    trial = @benchmark $call() samples = samples evals = 1 seconds = 600
    minimum_estimate = BenchmarkTools.minimum(trial)
    median_estimate = BenchmarkTools.median(trial)
    return Dict(
        "minimum_seconds" => minimum_estimate.time / 1e9,
        "median_seconds" => median_estimate.time / 1e9,
        "minimum_rows_per_second" => rows / (minimum_estimate.time / 1e9),
        "median_rows_per_second" => rows / (median_estimate.time / 1e9),
        "allocated_bytes" => median_estimate.memory,
        "allocations" => median_estimate.allocs,
        "raw_times_ns" => trial.times,
    )
end

function _measure_case(rows::Int, distribution::Symbol, samples::Int)
    inputs = _inputs(rows, distribution)
    threaded = Threads.nthreads() > 1
    scalar = _scalar_reference(inputs)
    outputs = _outputs(rows)
    full_call = () -> liljegren_wbgt!(
        outputs...,
        inputs.air,
        inputs.dew,
        inputs.wind,
        inputs.radiation,
        inputs.time,
        inputs.longitude,
        inputs.latitude;
        direct_fraction = 0.7,
        threaded,
    )
    _assert_result_equal(full_call(), scalar)

    preparation_call = _prepared_solar_call(inputs)
    prepared_zenith = preparation_call()
    scalar_zenith = _scalar_solar_preparation(inputs)
    prepared_zenith == scalar_zenith || error("prepared solar-zenith mismatch")

    serial_diagnostic = diagnose_liljegren_batch(
        inputs.air,
        inputs.dew,
        inputs.wind,
        inputs.radiation,
        inputs.time,
        inputs.longitude,
        inputs.latitude;
        direct_fraction = 0.7,
        threaded = false,
    )
    _assert_result_equal(serial_diagnostic.result, scalar)
    serial_diagnostic_digest = _diagnostic_digest(serial_diagnostic)
    status_counts = _status_counts(serial_diagnostic.input_status)
    all(==(InputAccepted), serial_diagnostic.input_status) ||
        error("valid benchmark input produced a rejected row")

    if threaded
        threaded_diagnostic = diagnose_liljegren_batch(
            inputs.air,
            inputs.dew,
            inputs.wind,
            inputs.radiation,
            inputs.time,
            inputs.longitude,
            inputs.latitude;
            direct_fraction = 0.7,
            threaded = true,
        )
        _diagnostic_digest(threaded_diagnostic) == serial_diagnostic_digest ||
            error("serial/threaded diagnostic mismatch")
    end

    result_digest = _result_digest(scalar)
    missing_counts = _missing_counts(scalar)
    full_measurement = _estimate(full_call, rows, samples)
    preparation_measurement = _estimate(preparation_call, rows, samples)
    _assert_result_equal(full_call(), scalar)

    return Dict(
        "rows" => rows,
        "distribution" => string(distribution),
        "threaded" => threaded,
        "scalar_value_digest" => result_digest,
        "batch_value_digest" => _result_digest(WBGTBatchResult{Float64}(outputs...)),
        "diagnostic_digest" => serial_diagnostic_digest,
        "missing_counts" => missing_counts,
        "status_counts" => status_counts,
        "value_equality" => true,
        "status_missingness_equality" => true,
        "solar_preparation" => preparation_measurement,
        "complete_public_call" => full_measurement,
    )
end

function _git_metadata()
    repository = pkgdir(HeatStress)
    return Dict(
        "path" => repository,
        "commit_sha" => readchomp(`git -C $repository rev-parse HEAD`),
        "dirty" => !isempty(readchomp(`git -C $repository status --porcelain`)),
    )
end

function _parse_arguments(args::Vector{String})
    samples = DEFAULT_SAMPLES
    rows = collect(DEFAULT_ROW_COUNTS)
    output_path = nothing
    for argument in args
        if startswith(argument, "--samples=")
            samples = parse(Int, split(argument, '='; limit = 2)[2])
        elseif startswith(argument, "--rows=")
            rows = parse.(Int, split(split(argument, '='; limit = 2)[2], ','))
        elseif startswith(argument, "--output=")
            output_path = split(argument, '='; limit = 2)[2]
        else
            error("unknown argument: $argument")
        end
    end
    samples > 0 && all(>(0), rows) ||
        throw(ArgumentError("samples and rows must be positive"))
    isnothing(output_path) && error("--output=<path> is required")
    return samples, rows, output_path
end

function main(args::Vector{String} = ARGS)
    samples, rows, output_path = _parse_arguments(args)
    measurements = Dict{String,Any}[]
    for row_count in rows
        for distribution in KEY_DISTRIBUTIONS
            push!(measurements, _measure_case(row_count, distribution, samples))
            GC.gc()
        end
    end
    report = Dict(
        "metadata" => Dict(
            "benchmark" => "cached batch solar geometry end-to-end acceptance matrix",
            "julia_version" => string(VERSION),
            "threads_available" => Threads.nthreads(),
            "cpu" => Sys.CPU_NAME,
            "timestamp_utc" => string(now(UTC)),
            "benchmarktools_version" => string(Base.pkgversion(BenchmarkTools)),
            "prepared_solar_implementation" =>
                isdefined(HeatStress, :_batch_solar_zenith),
            "repository" => _git_metadata(),
        ),
        "measurements" => measurements,
    )
    mkpath(dirname(output_path))
    open(output_path, "w") do io
        TOML.print(io, report)
    end
    println("wrote benchmark report: $output_path")
    return report
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
