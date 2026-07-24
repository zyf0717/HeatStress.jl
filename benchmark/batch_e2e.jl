# Reproducible Liljegren batch throughput benchmark.  Inputs, compilation,
# result validation and report writing are deliberately outside timed regions.
using BenchmarkTools
using Dates
using HeatStress
using TOML

const DEFAULT_ROW_COUNTS = (876_000,)
const DEFAULT_SAMPLES = 3

function batch_inputs(rows::Integer)
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
        time[row] = base_time + Minute(mod(row - 1, 240))
    end
    return (air, dew, wind, radiation, time)
end

function _validate(result::WBGTBatchResult)
    all(value -> !ismissing(value), result.wbgt_c) || error("benchmark produced missing WBGT")
    return nothing
end

function _measure(rows::Int, samples::Int, threaded::Bool)
    air, dew, wind, radiation, time = batch_inputs(rows)
    wbgt = Vector{Union{Missing,Float64}}(undef, rows)
    wet = similar(wbgt)
    globe = similar(wbgt)
    call!() = liljegren_wbgt!(wbgt, wet, globe, air, dew, wind, radiation, time, -74.0060, 40.7128; direct_fraction = 0.7, threaded)
    _validate(call!())
    trial = @benchmark $call!() samples = samples evals = 1
    _validate(call!())
    minimum_estimate, median_estimate = BenchmarkTools.minimum(trial), BenchmarkTools.median(trial)
    return Dict(
        "rows" => rows,
        "threaded" => threaded,
        "minimum_seconds" => minimum_estimate.time / 1e9,
        "median_seconds" => median_estimate.time / 1e9,
        "minimum_memory_bytes" => minimum_estimate.memory,
        "median_memory_bytes" => median_estimate.memory,
        "minimum_allocations" => minimum_estimate.allocs,
        "median_allocations" => median_estimate.allocs,
        "samples" => samples,
        "raw_times_ns" => trial.times,
    )
end

function _parse_arguments(args::Vector{String})
    samples, rows, output_path = DEFAULT_SAMPLES, collect(DEFAULT_ROW_COUNTS), nothing
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
    samples > 0 && all(>(0), rows) || throw(ArgumentError("samples and rows must be positive"))
    return samples, rows, output_path
end

function _git_metadata()
    repository = normpath(joinpath(@__DIR__, ".."))
    return Dict(
        "commit_sha" => readchomp(`git -C $repository rev-parse HEAD`),
        "dirty" => !isempty(readchomp(`git -C $repository status --porcelain`)),
    )
end

function main(args::Vector{String} = ARGS)
    samples, rows, output_path = _parse_arguments(args)
    threaded_modes = Threads.nthreads() > 1 ? (false, true) : (false,)
    measurements = [_measure(row_count, samples, threaded) for row_count in rows for threaded in threaded_modes]
    report = Dict(
        "metadata" => Dict(
            "benchmark" => "preallocated public Liljegren batch end-to-end throughput",
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
