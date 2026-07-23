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

The primary meteorological arrays and time array must have identical length. Row alignment is ordinal, not dependent on a shared starting index: row `j` is the `j`th element of each input. Allocating outputs use ordinary 1-based vectors; preallocated outputs are written in their own ordinal order.

Allow scalar or aligned arrays for:

- longitude;
- latitude;
- pressure;
- direct fraction.

Use internal ordinal scalar-or-vector accessors, not `repeat`/materialisation. The concrete methods must be restricted to supported scalar types rather than accepting arbitrary objects:

```julia
@inline _at(x::Real, row) = x
@inline _at(x::Missing, row) = missing
@inline _at(x::AbstractVector, row) =
    @inbounds x[firstindex(x) + row - 1]
```

Provide corresponding methods for time/location types as needed.

Before mutating output arrays, validate every aligned input length, every output length and element type, scalar configuration and the full indexability assumptions used by the ordinal loop.

## Output representation

Use `Vector{Union{Missing,T}}` for public allocated results in v0.1. Consider alternative masks only after profiling demonstrates a material bottleneck.

Preallocated output element types must accept `missing` and promoted `T`; otherwise throw a clear `ArgumentError` before mutation.

## Serial loop

Implement the serial loop first over ordinal rows `1:n`, translating each row to the corresponding index of each input/output:

```julia
for row in 1:n
    result = liljegren_wbgt(... row ...)
    write outputs
end
```

Use `@inbounds` only after complete validation, and create no hidden temporary row arrays.

The serial batch result is the correctness oracle for the threaded batch implementation.

## Threaded loop

After serial tests pass, add threading using `Threads.@threads` over stable contiguous ordinal ranges.

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
- dew-point-adjusted, wind-clamped and radiation-clamped flags;
- solar mismatch;
- each component's converged flag;
- failure reason;
- accepted value;
- candidate;
- Kelvin-scale validation residual;
- evaluations/iterations;
- initial/final brackets and native-equation endpoint location residuals.

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
