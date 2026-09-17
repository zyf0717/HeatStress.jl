# Reproducible solar-geometry batch benchmark for time-series, grouped, unique,
# and spatial-grid cardinalities. Scalar references and equality checks are
# outside timed regions.
using BenchmarkTools
using Dates
using HeatStress

const DEFAULT_ROWS = 100_000
const DEFAULT_SAMPLES = 5

function _inputs(rows::Int)
    base_time = DateTime(2024, 6, 21, 12)
    times = [base_time + Millisecond(index - 1) for index in 1:rows]
    longitude = [-100.0 + 30.0 * (index - 1) / rows for index in 1:rows]
    latitude = [30.0 + 20.0 * (index - 0.5) / rows for index in 1:rows]
    return times, longitude, latitude
end

function _grouped_coordinates(rows::Int)
    longitude = Vector{Float64}(undef, rows)
    latitude = Vector{Float64}(undef, rows)
    for index in eachindex(longitude)
        longitude[index], latitude[index] = isodd(index) ? (-74.0060, 40.7128) : (-73.9060, 40.8128)
    end
    return longitude, latitude
end

function _workload(
        mode::Symbol,
        times,
        longitude,
        latitude,
        grouped_longitude,
        grouped_latitude,
    )
    if mode === :fixed
        return times, -74.0060, 40.7128
    elseif mode === :grouped
        return times, grouped_longitude, grouped_latitude
    elseif mode === :unique
        return times, longitude, latitude
    elseif mode === :grid
        return fill(first(times), length(times)), longitude, latitude
    end
    throw(ArgumentError("unknown solar geometry workload: $mode"))
end

function _validate(mode::Symbol, actual, times, longitude, latitude)
    expected = solar_zenith.(times, longitude, latitude)
    actual == expected || error("solar batch/scalar mismatch for $mode")
    return nothing
end

function _measure(mode::Symbol, workload::Tuple, samples::Int)
    times, longitude, latitude = workload
    call = () -> solar_zenith_batch(times, longitude, latitude)
    _validate(mode, call(), workload...) # compile and validate before timing
    trial = @benchmark $call() samples = samples evals = 1
    _validate(mode, call(), workload...) # validate after timing

    minimum_estimate = BenchmarkTools.minimum(trial)
    median_estimate = BenchmarkTools.median(trial)
    unique_times = length(unique(times))
    unique_coordinates = longitude isa Real ? 1 :
        length(unique(zip(longitude, latitude)))
    println(
        "$mode rows=$(length(times)) unique_times=$unique_times " *
        "unique_coordinates=$unique_coordinates " *
        "minimum_seconds=$(minimum_estimate.time / 1e9) " *
        "median_seconds=$(median_estimate.time / 1e9) " *
        "minimum_allocations=$(minimum_estimate.allocs)",
    )
    return nothing
end

function main(rows::Int = DEFAULT_ROWS, samples::Int = DEFAULT_SAMPLES)
    rows > 0 || throw(ArgumentError("rows must be positive"))
    samples > 0 || throw(ArgumentError("samples must be positive"))
    times, longitude, latitude = _inputs(rows)
    grouped_longitude, grouped_latitude = _grouped_coordinates(rows)
    for mode in (:fixed, :grouped, :unique, :grid)
        workload = _workload(
            mode, times, longitude, latitude, grouped_longitude, grouped_latitude,
        )
        _measure(mode, workload, samples)
    end
    return nothing
end

function _parse_arguments(args::Vector{String} = ARGS)
    rows = DEFAULT_ROWS
    samples = DEFAULT_SAMPLES
    for argument in args
        if startswith(argument, "--rows=")
            rows = parse(Int, split(argument, '='; limit = 2)[2])
        elseif startswith(argument, "--samples=")
            samples = parse(Int, split(argument, '='; limit = 2)[2])
        else
            error(
                "usage: solar_geometry_e2e.jl [--rows=<positive integer>] " *
                "[--samples=<positive integer>]",
            )
        end
    end
    rows > 0 && samples > 0 ||
        throw(ArgumentError("rows and samples must be positive"))
    return rows, samples
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main(_parse_arguments()...)
