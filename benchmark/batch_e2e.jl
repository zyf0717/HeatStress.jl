# Reproducible Liljegren batch throughput benchmark. Inputs, compilation,
# equality validation and report writing are outside timed regions.
using BenchmarkTools
using Dates
using HeatStress
using TOML

const DEFAULT_ROW_COUNTS = (876_000,)
const DEFAULT_SAMPLES = 3
const GEOMETRY_MODES = (:fixed, :grouped, :unique)
const DEFAULT_GEOMETRY_MODES = (:fixed,)

function batch_inputs(rows::Integer, geometry::Symbol = :fixed)
    rows > 0 || throw(ArgumentError("rows must be positive"))
    time = Vector{DateTime}(undef, rows)
    air = Vector{Float64}(undef, rows)
    dew = Vector{Float64}(undef, rows)
    wind = Vector{Float64}(undef, rows)
    radiation = fill(750.0, rows)
    base_time = DateTime(2024, 6, 21, 16)
    for row in eachindex(air)
        phase = 2π * mod(row - 1, 240) / 240
        air[row] = 28.0 + 4.0 * sin(phase)
        dew[row] = air[row] - (5.0 + cos(phase))
        wind[row] = 0.5 + 1.5 * abs(sin(phase))
        time[row] = geometry === :unique ?
                    base_time + Millisecond(row - 1) :
                    base_time + Minute(mod(row - 1, 240))
    end
    longitude, latitude = if geometry === :fixed
        -74.0060, 40.7128
    elseif geometry === :grouped
        (
            [isodd(row) ? -74.0060 : 151.2093 for row in 1:rows],
            [isodd(row) ? 40.7128 : -33.8688 for row in 1:rows],
        )
    elseif geometry === :unique
        (
            [-100.0 + 30.0 * (row - 1) / rows for row in 1:rows],
            [30.0 + 20.0 * (row - 0.5) / rows for row in 1:rows],
        )
    else
        throw(ArgumentError("unknown geometry workload: $geometry"))
    end
    return (air, dew, wind, radiation, time, longitude, latitude)
end

function _outputs(rows::Int)
    values() = Vector{Union{Missing,Float64}}(undef, rows)
    return values(), values(), values()
end

_row_value(value::Real, ::Int) = value
_row_value(value::AbstractVector, row::Int) = @inbounds value[row]

function _scalar_row_loop!(
    wbgt, wet, globe, air, dew, wind, radiation, time, longitude, latitude,
)
    for row in eachindex(air)
        result = HeatStress.liljegren_wbgt(
            air[row], dew[row], wind[row], time[row],
            _row_value(longitude, row), _row_value(latitude, row);
            ghi_w_m2 = radiation[row], partition = FixedDirectFraction(0.7),
        )
        wbgt[row] = result.wbgt_c
        wet[row] = result.natural_wet_bulb_c
        globe[row] = result.globe_temperature_c
    end
    return WBGTBatchResult{Float64}(wbgt, wet, globe)
end

function _scalar_public_results(
    air, dew, wind, radiation, time, longitude, latitude,
)
    results = Vector{WBGTResult{Float64}}(undef, length(air))
    for row in eachindex(air)
        results[row] = HeatStress.liljegren_wbgt(
            air[row], dew[row], wind[row], time[row],
            _row_value(longitude, row), _row_value(latitude, row);
            ghi_w_m2 = radiation[row], partition = FixedDirectFraction(0.7),
        )
    end
    return results
end

function _validate(result::WBGTBatchResult)
    all(value -> !ismissing(value), result.wbgt_c) || error("benchmark produced missing WBGT")
    return nothing
end

function _assert_equal(actual::WBGTBatchResult, expected::WBGTBatchResult)
    isequal(actual.wbgt_c, expected.wbgt_c) || error("benchmark WBGT result mismatch")
    isequal(actual.natural_wet_bulb_c, expected.natural_wet_bulb_c) || error("benchmark wet-bulb result mismatch")
    isequal(actual.globe_temperature_c, expected.globe_temperature_c) || error("benchmark globe result mismatch")
    return nothing
end

function _assert_equal(actual::Vector{WBGTResult{Float64}}, expected::WBGTBatchResult)
    isequal([result.wbgt_c for result in actual], expected.wbgt_c) ||
        error("benchmark scalar WBGT result mismatch")
    isequal([result.natural_wet_bulb_c for result in actual], expected.natural_wet_bulb_c) ||
        error("benchmark scalar wet-bulb result mismatch")
    isequal([result.globe_temperature_c for result in actual], expected.globe_temperature_c) ||
        error("benchmark scalar globe result mismatch")
    return nothing
end

function _measure(inputs, samples::Int, mode::Symbol, geometry::Symbol)
    air, dew, wind, radiation, time, longitude, latitude = inputs
    rows = length(air)
    reference_outputs = _outputs(rows)
    reference = _scalar_row_loop!(
        reference_outputs..., air, dew, wind, radiation, time,
        longitude, latitude,
    )
    _validate(reference)

    call = if mode === :public_scalar_results
        () -> _scalar_public_results(
            air, dew, wind, radiation, time, longitude, latitude,
        )
    elseif mode === :public_scalar_preallocated
        outputs = _outputs(rows)
        () -> _scalar_row_loop!(
            outputs..., air, dew, wind, radiation, time, longitude, latitude,
        )
    elseif mode === :preallocated_batch_serial || mode === :preallocated_batch_threaded
        outputs = _outputs(rows)
        threaded = mode === :preallocated_batch_threaded
        () -> HeatStress.liljegren_wbgt!(
            outputs..., air, dew, wind, time, longitude, latitude;
            ghi_w_m2 = radiation, partition = FixedDirectFraction(0.7), threaded,
        )
    elseif mode === :allocating_batch
        () -> HeatStress.liljegren_wbgt_batch(
            air, dew, wind, time, longitude, latitude;
            ghi_w_m2 = radiation, partition = FixedDirectFraction(0.7),
        )
    else
        throw(ArgumentError("unknown benchmark mode: $mode"))
    end

    _assert_equal(call(), reference) # compile and validate before timing
    trial = @benchmark $call() samples = samples evals = 1 seconds = 600
    result = call()
    result isa WBGTBatchResult && _validate(result)
    _assert_equal(result, reference)
    minimum_estimate, median_estimate = BenchmarkTools.minimum(trial), BenchmarkTools.median(trial)
    return Dict(
        "mode" => string(mode),
        "geometry" => string(geometry),
        "rows" => rows,
        "minimum_seconds" => minimum_estimate.time / 1e9,
        "median_seconds" => median_estimate.time / 1e9,
        "median_rows_per_second" => rows / (median_estimate.time / 1e9),
        "minimum_memory_bytes" => minimum_estimate.memory,
        "median_memory_bytes" => median_estimate.memory,
        "minimum_allocations" => minimum_estimate.allocs,
        "median_allocations" => median_estimate.allocs,
        "samples" => samples,
        "raw_times_ns" => trial.times,
    )
end

function _parse_arguments(args::Vector{String})
    samples = DEFAULT_SAMPLES
    rows = collect(DEFAULT_ROW_COUNTS)
    geometries = collect(DEFAULT_GEOMETRY_MODES)
    output_path = nothing
    for argument in args
        if startswith(argument, "--samples=")
            samples = parse(Int, split(argument, '='; limit = 2)[2])
        elseif startswith(argument, "--rows=")
            rows = parse.(Int, split(split(argument, '='; limit = 2)[2], ','))
        elseif startswith(argument, "--output=")
            output_path = split(argument, '='; limit = 2)[2]
        elseif startswith(argument, "--geometry=")
            geometries = Symbol.(split(split(argument, '='; limit = 2)[2], ','))
        else
            error("unknown argument: $argument")
        end
    end
    samples > 0 && all(>(0), rows) || throw(ArgumentError("samples and rows must be positive"))
    all(geometry -> geometry in GEOMETRY_MODES, geometries) ||
        throw(ArgumentError("geometry must be fixed, grouped, or unique"))
    return samples, rows, geometries, output_path
end

function _git_metadata()
    repository = normpath(joinpath(@__DIR__, ".."))
    return Dict(
        "commit_sha" => readchomp(`git -C $repository rev-parse HEAD`),
        "dirty" => !isempty(readchomp(`git -C $repository status --porcelain`)),
    )
end

function main(args::Vector{String} = ARGS)
    samples, rows, geometries, output_path = _parse_arguments(args)
    modes = Symbol[
        :public_scalar_results,
        :public_scalar_preallocated,
        :preallocated_batch_serial,
        :allocating_batch,
    ]
    Threads.nthreads() > 1 && push!(modes, :preallocated_batch_threaded)
    measurements = Dict{String,Any}[]
    for row_count in rows, geometry in geometries
        inputs = batch_inputs(row_count, geometry)
        append!(
            measurements,
            (_measure(inputs, samples, mode, geometry) for mode in modes),
        )
    end
    report = Dict(
        "metadata" => Dict(
            "benchmark" => "comparable public scalar and Liljegren batch end-to-end throughput",
            "julia_version" => string(VERSION),
            "threads_available" => Threads.nthreads(),
            "cpu" => Sys.CPU_NAME,
            "timestamp_utc" => string(now(UTC)),
            "benchmarktools_version" => string(Base.pkgversion(BenchmarkTools)),
            "result_scope" => "local batch baseline evidence; not a cross-language comparison or scientific correctness gate",
            "repository" => _git_metadata(),
        ),
        "measurements" => measurements,
    )
    if isnothing(output_path)
        TOML.print(stdout, report)
    else
        mkpath(dirname(output_path))
        open(output_path, "w") do io
            TOML.print(io, report)
        end
        println("wrote benchmark report: $output_path")
    end
    return report
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
