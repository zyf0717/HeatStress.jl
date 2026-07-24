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
    direct_fraction,
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
    direct_fraction,
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

Longitude and latitude must be non-missing `Real` values. Coordinate vectors
must have a concrete non-missing real element type and may not permit
`Missing`; malformed or missing coordinates are rejected before any
preallocated output is written.

Direct fraction is required as a scalar or aligned numeric value in `[0, 1]`.
It is not derived from spec-004 solar geometry, and there is no package
fallback batch default.

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

Preallocated output element types must accept `missing` and promoted `T`; otherwise throw a clear `ArgumentError` before mutation. Their axes need not match: every output is written in ordinal row order. Reject output-output and output-input aliasing before mutation.

## Serial loop

The public scalar APIs and both batch APIs share one canonical typed row path.
At its public boundary, scalar execution determines the promoted floating type and
converts `LiljegrenConfig` once, then calls the internal time-based row path.
Batch execution does the same conversion once per batch before its ordinal loop;
the loop must not call `liljegren_wbgt` or `diagnose_liljegren` per row.

The internal path is conceptually split into a time form and a prepared-zenith
form. The time form computes solar geometry and calls the prepared-zenith form,
which owns the shared meteorological preparation and component solves. Neither
method is public. Value-mode rows return a compact isbits internal outcome; the
public scalar boundary alone materializes `WBGTResult`, while a preallocated
batch loop writes its three fields directly to caller outputs.

Implement the serial loop over ordinal rows `1:n`, translating each row to the corresponding index of each input/output:

```julia
for row in 1:n
    values = _liljegren_row_from_time(... row ..., typed_config, _ValueMode())
    write outputs from values
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

Row-dependent solar geometry and all downstream scientific computation remain
inside each worker iteration. The orchestration thread may validate, convert
configuration, allocate required outputs, and select scheduling, but must not
add a serial whole-batch solar or meteorological preprocessing pass. Any future
material preprocessing must itself be parallelised.

For small arrays, permit automatic serial execution even when `threaded=true`; define and document a threshold only after benchmarking. Initially, respect `threaded=true` literally to keep semantics simple.

## Solar geometry reuse

Spec 008 retains worker-local, row-by-row solar geometry as its fused
correctness and scaling baseline. It provides the private prepared-zenith row
form only to permit later investigation without duplicating scientific logic.
Grouped solar caching, unique-key preprocessing, SIMD, residual-equation
restructuring, specialized fixed-station kernels, and advanced batch solvers
are deferred to spec 011 after profiling. A future prepared-zenith path must
parallelise its preparation phase and retain end-to-end numerical equivalence.

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

Value-only v0.1 batch calls emit no aggregate warnings. Failed or rejected rows
remain `missing`; callers requiring reasons use `diagnose_liljegren_batch`.
Aggregate warnings are deferred until a lightweight status path is justified
without constructing diagnostics. A future warning policy may emit one warning
like:

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
- no value-only aggregate warning in v0.1; any future warning feature requires
  zero/one/multiple-failure aggregate-warning tests;
- diagnostic row alignment;
- test under `JULIA_NUM_THREADS=1` and multi-threaded CI job.

## Performance acceptance criteria

Do not require a speedup from threading on tiny arrays.

For a representative Float64 fixture on a multicore developer machine:

- compare preallocated serial batch with a public scalar row loop writing the
  same three preallocated component arrays, using identical structure-of-arrays
  inputs, row order, controls and output validation;
- threaded mode should not be materially slower than serial at sufficiently large row counts;
- outputs must remain equal before performance claims are accepted.

The serial preallocated path must remove avoidable public-wrapper and public
result-container work. A large wall-clock speedup is not required when the
nonlinear component solves dominate, but an unexplained regression is
unacceptable. End-to-end timings include all work required by the public batch
call; a future prepared-zenith phase must never be excluded from that primary
measurement.

The cross-implementation benchmark against HeatStressR v2.1.6 is required by
spec 011, not by this unit. Spec 008 closes on correctness and usable batch
interfaces so that comparison work can begin without waiting for secondary
indices or release polish.

Performance goals are directional, not a registration blocker:

- no material regression against the identical public scalar/preallocated-output
  control, and acceptable threaded scaling on large workloads;
- no PSOCK serialisation or R worker startup costs;
- preallocated calls allocate no replacement result arrays; total allocations
  from the shared scalar value path are measured and documented before further
  optimization rather than assumed to be fixed.

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
- scalar and batch routes share the canonical typed scientific row path;
- configuration converts once per batch and preallocated value mode does not
  materialize `WBGTResult` per row;
- worker-local solar computation is retained in threaded execution.

## Suggested commit

`feat: add batch and threaded Liljegren execution`
