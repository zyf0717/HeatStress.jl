# Liljegren performance benchmarking

## Purpose

Reach a reproducible, correctness-gated performance comparison between
HeatStress.jl and the local HeatStressR v2.1.6 checkout, then optimise only
measured Julia bottlenecks. Publication polish and release-wide quality work are
deferred to spec 012.

## Benchmark milestone

The reference checkout is the sibling `../HeatStressR` repository (currently
`~/repos/HeatStressR`). Allow an explicit path override for portability. Before
every comparison run, verify that its `DESCRIPTION` declares version `2.1.6`.
Record its Git commit and dirty state; do not silently benchmark another version
or a modified tree.

Use HeatStressR only through its exported public API as a black box. Do not copy
or translate its source, benchmark scripts, fixtures, comments or structure.
Repository tests and package execution must remain independent of R. Any
cross-language adapter and raw comparison output belong under an ignored
`local-comparison/` workspace.

The milestone covers:

1. scalar Liljegren value calculation;
2. serial allocating and preallocated Julia batch paths;
3. threaded Julia batch at available thread counts;
4. the corresponding public HeatStressR v2.1.6 scalar, batch and parallel paths;
5. fixed-station, grouped-location and unique-triplet workloads.

Secondary indices, documentation styling, package registration and release
automation do not block this milestone.

## Benchmark contract

Use `BenchmarkTools.jl` for Julia and a documented monotonic elapsed timer for
R. Separate setup from timed code. Precompile before measurement. Do not include
fixture generation, exchange-file loading or compilation in core timings.

Benchmark groups:

1. solar geometry scalar;
2. solar geometry fixed/grouped/unique batch;
3. component scalar solves;
4. Liljegren scalar repeated loop;
5. allocating serial batch;
6. preallocated serial batch;
7. preallocated threaded batch;
8. value-only versus diagnostic APIs;
9. HeatStressR v2.1.6 public scalar, batch and parallel calls.

Row sizes:

- 1;
- 100;
- 1,000;
- 10,000;
- 100,000;
- 1,000,000.

Coordinate modes:

- fixed station;
- grouped locations with repeated timestamps;
- unique `(time, lon, lat)` triplets.

## Comparison protocol

Julia baselines must include:

- repeated calls to the public scalar Julia API;
- a tight loop over the internal scalar kernel;
- allocating serial batch;
- preallocated serial batch;
- threaded batch at multiple thread counts;
- solar preprocessing on and off where applicable.

Generate one deterministic, implementation-independent dataset for both
languages. Use identical row order, meteorology, coordinates, timestamps,
pressure, direct fraction and physical controls. The exchange-file generation,
loading and conversion steps are setup and must not be included in timed
regions.

Before timing:

- load and warm each implementation;
- confirm the HeatStressR version and record both repository revisions;
- compare WBGT, natural wet-bulb and globe outputs using declared absolute and
  relative tolerances;
- compare missing/failed row sets, while allowing documented differences in
  diagnostic vocabulary;
- investigate and record any material mismatch against the scientific sources
  or independent fixtures.

Do not report a speed ratio for a workload whose outputs have not passed this
gate. Agreement with HeatStressR is advisory and must not override the
conformance hierarchy in spec 000.

The primary end-to-end timing starts immediately before the public computation
call and ends when its result is materialised. Exclude Julia/R process startup,
package loading, Julia compilation, input parsing and result formatting. Include
any worker startup or orchestration performed inside the timed public call.
Use the same warm-up policy and sample count, report minimum and median elapsed
time, and do not compare unequal row counts.

Measure serial execution in both languages. Measure parallel execution at
matched concurrency levels supported by the machine, including 1 and at least
one multi-core setting. Record Julia threads, HeatStressR workers and physical
hardware; do not imply that threads and processes have identical overhead.

## Optimisation order

Start from the completed spec-008 worker-local fused baseline:

```text
solar geometry → meteorological preparation → component solves → output write
```

Use this order:

1. profile the fused spec-008 path;
2. inspect type stability and allocations;
3. identify repeated batch invariants;
4. compare the fused worker-local solar calculation with a parallel
   prepared-zenith path only if solar geometry is material;
5. test grouped solar reuse for repeated timestamp/location keys;
6. reduce repeated row-local invariant calculations in residual evaluation;
7. consider kernel inlining;
8. consider SIMD only for simple preprocessing loops;
9. consider advanced batch solving only if root solving remains dominant.

The parallel prepared-zenith candidate is two worker-parallel phases: a
parallel zenith pass, a barrier, then a parallel WBGT pass. Do not calculate
the whole zenith array on the orchestration thread. For repeated
`(time, longitude, latitude)` keys, profile grouping/deduplication and include
key construction, grouping, parallel unique computation and scattering in the
end-to-end timing. Possible designs include per-thread local caches,
chunk-local preparation and parallel preprocessing; do not add a shared mutable
global cache or lock contention to the row hot path.

An optimisation must not improve isolated kernel timing while reducing
end-to-end threaded scaling by consolidating material work onto the
orchestration thread. For each retained preprocessing optimisation, measure
one-thread and multi-thread end-to-end time, preprocessing and solver phases,
total speedup, allocations and numerical equivalence. Reject or redesign it
when serial O(n) preprocessing, degraded scaling, shared-cache contention,
memory traffic or complexity outweighs measured reuse.

Do not use `@fastmath` in the production scientific path. A separately named approximate mode is out of scope for v0.1.

## Allocation targets

After compilation:

- direct scalar physical kernels: zero allocations;
- scalar value-only Liljegren: target zero allocations for `DateTime`, or document a small fixed count;
- preallocated batch: first establish the spec-008 baseline with no replacement
  output arrays and no public result container per row. Further allocation
  reductions require profile evidence; do not claim constant allocations until
  measured on supported Julia versions;
- allocating batch: allocations dominated by output arrays;
- diagnostics: proportional to required diagnostic arrays only.

Add allocation regression tests with conservative thresholds on one supported Julia version. Avoid brittle exact byte counts across versions.

## Benchmark-readiness checks

Analyse representative public calls with JET and `@code_warntype`. Treat
definite runtime dispatch or errors in hot paths as failures. Add conservative
allocation regression tests and a small Julia-only benchmark smoke path that
validates outputs without enforcing timings.

Do not enforce wall-clock benchmark thresholds in shared GitHub-hosted CI.
Cross-language comparison must not run in ordinary CI.

## Performance reporting

The local comparison report must record:

- hardware/OS/Julia version;
- R version and the commits/dirty states of both packages;
- BenchmarkTools version and timing method used for R;
- Julia thread count and HeatStressR worker count;
- input size and coordinate mode;
- diagnostic mode;
- minimum/median time and allocations;
- correctness tolerance used in comparisons.

Also record raw per-sample timings or a machine-readable summary sufficient to
recalculate reported statistics. A concise milestone summary may be added to
`tasks.md`; raw output and private adapters stay in `local-comparison/`.

Public performance documentation is deferred to spec 012. A local result is not
automatically a publishable claim.

## Acceptance criteria

- no type instability in core scalar path;
- no per-row heap container in preallocated batch;
- threaded mode has serial-equivalence tests;
- benchmark scripts are reproducible and save metadata;
- the local reference is verified as HeatStressR v2.1.6 and its commit/dirty
  state is recorded;
- correctness-gated scalar, serial batch and parallel comparisons complete for
  fixed, grouped and unique coordinate modes;
- a local report records timing boundaries, runtime/hardware metadata,
  tolerances and unresolved discrepancies;
- optimisation decisions cite profiles or benchmark evidence;
- no unsubstantiated performance claims in README;
- package remains correct with bounds checks enabled.

## Suggested commit

`perf: benchmark Liljegren against HeatStressR 2.1.6`
