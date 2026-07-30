# Reproducible end-to-end scalar Liljegren throughput benchmark. The timed
# region materializes one `WBGTResult` per row through the public scalar API.
# Dataset construction, warmup, validation, and report writing are outside it.
using BenchmarkTools
using Dates
using HeatStress
using TOML

const DEFAULT_ROW_COUNTS = (10_000, 100_000, 1_000_000)
const DEFAULT_SAMPLES = 3

struct ScalarInput
    air_temperature_c::Float64
    dew_point_c::Float64
    wind_speed_m_s::Float64
    solar_radiation_w_m2::Float64
    time::DateTime
    longitude_deg::Float64
    latitude_deg::Float64
    pressure_hpa::Float64
    direct_fraction::Float64
end

"""Create a deterministic fixed-station workload with ordinary valid inputs."""
function scalar_inputs(row_count::Integer)
    row_count > 0 || throw(ArgumentError("row_count must be positive"))
    inputs = Vector{ScalarInput}(undef, row_count)
    # Keep the ordinary throughput profile well clear of the direct-beam
    # near-horizon guardrail. Boundary cases belong to a separate edge suite.
    base_time = DateTime(2024, 6, 21, 16)
    for index in eachindex(inputs)
        phase = 2π * mod(index - 1, 240) / 240
        air_temperature_c = 28.0 + 4.0 * sin(phase)
        inputs[index] = ScalarInput(
            air_temperature_c,
            air_temperature_c - (5.0 + cos(phase)),
            0.5 + 1.5 * abs(sin(phase)),
            750.0,
            base_time + Minute(mod(index - 1, 240)),
            -74.0060,
            40.7128,
            1010.0,
            0.7,
        )
    end
    return inputs
end

"""Process `count` rows through the public scalar API and materialize results."""
function process_scalar_e2e(inputs::Vector{ScalarInput}, count::Int = length(inputs))
    0 <= count <= length(inputs) || throw(ArgumentError("count must lie within the input length"))
    results = Vector{WBGTResult{Float64}}(undef, count)
    for index in 1:count
        input = inputs[index]
        results[index] = HeatStress.liljegren_wbgt(
            input.air_temperature_c,
            input.dew_point_c,
            input.wind_speed_m_s,
            input.time,
            input.longitude_deg,
            input.latitude_deg;
            ghi_w_m2 = input.solar_radiation_w_m2,
            pressure_hpa = input.pressure_hpa,
            partition = FixedDirectFraction(input.direct_fraction),
        )
    end
    return results
end

function _validate_results(results::Vector{WBGTResult{Float64}})
    all(result -> !ismissing(result.wbgt_c) && !ismissing(result.natural_wet_bulb_c) &&
                  !ismissing(result.globe_temperature_c), results) ||
        error("benchmark workload produced a missing component")
    return nothing
end

function _measure(row_count::Int, samples::Int)
    inputs = scalar_inputs(row_count)
    _validate_results(process_scalar_e2e(inputs, 1)) # compilation/warmup outside timing
    trial = @benchmark process_scalar_e2e($inputs) samples = samples evals = 1
    _validate_results(process_scalar_e2e(inputs))
    minimum_estimate = BenchmarkTools.minimum(trial)
    median_estimate = BenchmarkTools.median(trial)
    return Dict(
        "rows" => row_count,
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

function _git_metadata()
    repository = normpath(joinpath(@__DIR__, ".."))
    return Dict(
        "commit_sha" => readchomp(`git -C $repository rev-parse HEAD`),
        "dirty" => !isempty(readchomp(`git -C $repository status --porcelain`)),
    )
end

function _parse_arguments(args::Vector{String})
    samples = DEFAULT_SAMPLES
    row_counts = collect(DEFAULT_ROW_COUNTS)
    output_path = nothing
    for argument in args
        if startswith(argument, "--samples=")
            samples = parse(Int, split(argument, '='; limit = 2)[2])
        elseif startswith(argument, "--rows=")
            row_counts = parse.(Int, split(split(argument, '='; limit = 2)[2], ','))
        elseif startswith(argument, "--output=")
            output_path = split(argument, '='; limit = 2)[2]
        else
            error("unknown argument: $argument")
        end
    end
    samples > 0 || throw(ArgumentError("samples must be positive"))
    all(>(0), row_counts) || throw(ArgumentError("all row counts must be positive"))
    return samples, row_counts, output_path
end

function main(args::Vector{String} = ARGS)
    samples, row_counts, output_path = _parse_arguments(args)
    measurements = [_measure(row_count, samples) for row_count in row_counts]
    report = Dict(
        "metadata" => Dict(
            "benchmark" => "public scalar Liljegren end-to-end fixed-station throughput",
            "julia_version" => string(VERSION),
            "threads" => Threads.nthreads(),
            "cpu" => Sys.CPU_NAME,
            "timestamp_utc" => string(now(UTC)),
            "benchmarktools_version" => string(Base.pkgversion(BenchmarkTools)),
            "result_scope" => "local baseline evidence; not a cross-language comparison or scientific correctness gate",
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

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
