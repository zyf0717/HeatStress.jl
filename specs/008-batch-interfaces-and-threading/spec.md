# Batch interfaces and threading

## Purpose

Add high-throughput aligned-array interfaces around the canonical scalar model without assuming that a prior vectorised solver architecture is appropriate for Julia.

## Public batch signatures

Value-returning allocation API:

```julia
liljegren_wbgt_batch(
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    solar_radiation_w_m2,
    time,
    longitude_deg,
    latitude_deg;
    pressure_hpa = 1010,
    direct_fraction = 0.8,
    config = LiljegrenConfig(),
    threaded = false,
)
```

Preallocated API:

```julia
liljegren_wbgt!(
    wbgt_out,
    natural_wet_bulb_out,
    globe_temperature_out,
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    solar_radiation_w_m2,
    time,
    longitude_deg,
    latitude_deg;
    pressure_hpa = 1010,
    direct_fraction = 0.8,
    config = LiljegrenConfig(),
    threaded = false,
)
```

Diagnostic allocation API:

```julia
diagnose_liljegren_batch(...; threaded=false)
```

Do not add a `workers` argument. Julia threads are started outside the package via `JULIA_NUM_THREADS`/`--threads`; the package decides only whether to use available threads.

## Accepted argument shapes

The primary meteorological arrays and time array must have identical length.

Allow scalar or aligned arrays for:

- longitude;
- latitude;
- pressure;
- direct fraction.

Use an internal scalar-or-vector accessor, not `repeat`/materialisation:

```julia
@inline _at(x::Number, i) = x
@inline _at(x::AbstractVector, i) = @inbounds x[i]
```

Provide corresponding methods for time/location types as needed.

Reject mismatched aligned lengths before mutating output arrays.

## Output representation

Use `Vector{Union{Missing,T}}` for public allocated results in v0.1. Consider alternative masks only after profiling demonstrates a material bottleneck.

Preallocated output element types must accept `missing` and promoted `T`; otherwise throw a clear `ArgumentError` before mutation.

## Serial loop

Implement the serial loop first:

```julia
for i in eachindex(...)
    result = liljegren_wbgt(... row i ...)
    write outputs
end
```

Use `eachindex`, `@inbounds` only after length validation, and no hidden temporary row arrays.

The serial batch result is the correctness oracle for the threaded batch implementation.

## Threaded loop

After serial tests pass, add threading using `Threads.@threads` over stable contiguous index ranges.

Rules:

- each iteration writes only to its own output index;
- configs and constants are immutable;
- no shared counters or push operations;
- aggregate warnings are based on per-row statuses collected after the loop;
- results must not depend on thread count or scheduling;
- no nested threading detection beyond a documented simple policy in v0.1;
- do not change global thread configuration;
- do not create processes.

For small arrays, permit automatic serial execution even when `threaded=true`; define and document a threshold only after benchmarking. Initially, respect `threaded=true` literally to keep semantics simple.

## Solar geometry reuse

Implement in two stages.

### v0.1 correctness stage

Each scalar row may calculate its own zenith. Establish correctness and baseline performance.

### optimisation stage

Profile. If solar geometry is material, precompute a zenith array using the grouped/unique-time implementation from spec 04, then pass prepared zenith into an internal row solver. This is preferable to moving all computation into R-style worker chunks.

The precomputed and row-by-row paths must have exact or documented-tolerance equality.

## Diagnostic batch layout

Use structure-of-arrays. Required row-aligned fields:

- input status;
- solar mismatch;
- each component's converged flag;
- failure reason;
- accepted value;
- candidate;
- final residual;
- evaluations/iterations;
- initial/final brackets and endpoint residuals.

Include batch metadata:

- `threaded::Bool`;
- `threads_available::Int`;
- `rows::Int`.

Do not claim a fixed number of threads was used unless explicitly measured.

## Aggregate warning

Value-only batch call may emit one warning like:

```text
Liljegren solving failed for X of Y attempted rows; valid component
values were retained and complete WBGT is missing for affected rows.
Call diagnose_liljegren_batch for row-level details.
```

Do not warn for missing/unattempted rows. Do not emit one warning per row or per component.

## Tests

- empty input;
- one row;
- mismatched primary arrays;
- scalar and aligned pressure/direct fraction/location;
- fixed, grouped and unique coordinates;
- serial batch versus scalar row loop;
- threaded versus serial exact missingness/status;
- threaded versus serial values within zero or tight tolerance;
- output order preservation;
- preallocated versus allocating API;
- invalid output lengths/types cause no partial mutation;
- aggregate warning count;
- diagnostic row alignment;
- test under `JULIA_NUM_THREADS=1` and multi-threaded CI job.

## Performance acceptance criteria

Do not require a speedup from threading on tiny arrays.

For a representative 876,000-row Float64 fixture on a multicore developer machine:

- serial Julia batch should be benchmarked against its scalar kernel; optional private comparisons to HeatStressR may be recorded separately;
- threaded mode should not be materially slower than serial at sufficiently large row counts;
- outputs must remain equal before performance claims are accepted.

Performance goals are directional, not a registration blocker:

- substantial improvement over repeated public scalar calls and acceptable scaling on large workloads;
- no PSOCK serialisation or R worker startup costs;
- allocations scale mainly with output and diagnostics arrays, not per-row temporary containers.

## Forbidden shortcuts

- no direct translation of `foreach`/PSOCK backend capture/restore;
- no one-task-per-row scheduling;
- no mutation of caller input arrays;
- no DataFrame construction in computation;
- no lockstep vector root solver until scalar-loop profiling justifies it.

## Acceptance criteria

- serial and threaded tests pass on all platforms;
- batch API accepts generic `AbstractVector`, not only `Vector{Float64}`;
- no process-based parallel dependency exists;
- preallocated API performs no result-array allocations;
- scientific fixtures pass for serial and threaded modes.

## Suggested commit

`feat: add batch and threaded Liljegren execution`

