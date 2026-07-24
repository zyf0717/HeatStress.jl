# Reproducible solar-geometry batch benchmark for fixed, grouped, and unique
# coordinates. It validates batch/scalar equality before every timed trial.
using BenchmarkTools
using Dates
using HeatStress

const DEFAULT_ROWS = 100_000

function _inputs(rows::Int)
    times = [DateTime(2024, 6, 21, 12) + Minute(mod(index, 1_440)) for index in 1:rows]
    longitude = [-74.0060 + 0.1 * mod(index, 10) for index in 1:rows]
    latitude = [40.7128 + 0.1 * mod(index, 10) for index in 1:rows]
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

function _check(mode::Symbol, times, longitude, latitude, grouped_longitude, grouped_latitude)
    actual = mode === :fixed ? solar_zenith_batch(times, -74.0060, 40.7128) :
             mode === :grouped ? solar_zenith_batch(times, grouped_longitude, grouped_latitude) :
             solar_zenith_batch(times, longitude, latitude)
    expected = mode === :fixed ? solar_zenith.(times, -74.0060, 40.7128) :
               mode === :grouped ? solar_zenith.(times, grouped_longitude, grouped_latitude) :
               solar_zenith.(times, longitude, latitude)
    actual == expected || error("solar batch/scalar mismatch for $mode")
    return actual
end

function main(rows::Int = DEFAULT_ROWS)
    times, longitude, latitude = _inputs(rows)
    grouped_longitude, grouped_latitude = _grouped_coordinates(rows)
    for mode in (:fixed, :grouped, :unique)
        call = () -> _check(mode, times, longitude, latitude, grouped_longitude, grouped_latitude)
        call() # compilation and correctness are outside the timed region
        trial = @benchmark $call() samples = 1 evals = 1
        estimate = BenchmarkTools.minimum(trial)
        println("$mode rows=$rows seconds=$(estimate.time / 1e9) allocations=$(estimate.allocs)")
    end
    return nothing
end

function _rows_from_args(args::Vector{String} = ARGS)
    isempty(args) && return DEFAULT_ROWS
    length(args) == 1 && startswith(first(args), "--rows=") ||
        error("usage: solar_geometry_e2e.jl [--rows=<positive integer>]")
    rows = parse(Int, split(first(args), '='; limit = 2)[2])
    rows > 0 || throw(ArgumentError("rows must be positive"))
    return rows
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main(_rows_from_args())
