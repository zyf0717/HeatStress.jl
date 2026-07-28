# Liljegren performance benchmarking

## Purpose

Maintain reproducible performance evidence for released Liljegren paths. The
initial `v0.1.0` gate establishes that the existing implementation is usable,
stable and non-regressing; a complete HeatStressR comparison and further
optimisation are post-publication work.

## Tier 1: v0.1.0 publication gate

The release gate requires:

- reproducible Julia scalar and batch benchmark harnesses with deterministic
  inputs and correctness checks outside timed regions;
- no material regression from the recorded readable/fused baseline after the
  readability refactor;
- usable threaded scaling on the recorded host;
- JET and allocation review for released scalar and batch hot paths;
- a small Julia-only benchmark smoke test that validates outputs without a
  wall-clock threshold;
- public documentation that labels results as host-specific local evidence.

The existing identical-input baseline is adequate initial evidence: on the
recorded `znver3` host with Julia 1.10.11 and four threads, one million
preallocated serial batch rows had a 4.328 s median and four-thread batch had a
1.255 s median (3.45× serial speedup). These measurements establish a useful
publication baseline, not a universal promise or a public cross-language
comparison.

Current maintainer observation indicates the Julia implementation may be about
twice as fast as optimised HeatStressR v2.1.6. It is advisory only: do not make
that ratio a README, documentation or release claim until a reproducible,
correctness-gated report supporting the exact workload and ratio is committed.

Do not delay v0.1.0 for optimisation unless profiling or review finds a
correctness, stability or usability blocker.

## Tier 2: post-publication comparison and optimisation

After v0.1.0, retain the following work as optional, profile-led tasks:

1. verify the local HeatStressR v2.1.6 checkout and record both revisions;
2. create an ignored public-API black-box adapter and correctness-gated scalar,
   serial batch and matched-concurrency comparison matrix;
3. cover fixed-station, grouped-location and unique-triplet workloads at the
   selected row sizes;
4. profile released hot paths before considering prepared-zenith passes,
   grouped-key reuse, allocation reduction, solver changes, inlining or SIMD;
5. retain an optimisation only when it improves complete end-to-end timing
   without degrading numerical equivalence or threaded scaling.

Use HeatStressR only through its exported public API as a black box. Do not
copy or translate its source, benchmark scripts, fixtures, comments or
structure. Adapters and raw comparison output remain in ignored
`local-comparison/` workspace. Agreement with another implementation is
advisory and never overrides the scientific hierarchy in spec 000.

## Benchmark contract

Use `BenchmarkTools.jl` for Julia. Separate input construction, compilation,
output validation and report writing from timed regions. Record Julia version,
threads, hardware, BenchmarkTools version, repository revision/dirty state,
row count, mode, minimum/median time and allocations.

The Tier 1 harnesses cover public scalar results, public scalar writes to
preallocated outputs, preallocated serial batch, allocating serial batch and,
when threads are available, preallocated threaded batch. Each mode must use
identical inputs and check WBGT/component equality before timing.

Prepared-solar optimisation experiments use complete public Liljegren batch
calls at 10,000, 100,000 and 1,000,000 rows with one and four Julia threads.
The matrix covers fixed/repeated, grouped and unique timestamp/coordinate keys
from separate clean worktrees at `v0.1.0` and the candidate revision. Record
minimum/median wall time, throughput, allocations, bytes, solar-preparation
time, complete-call time and exact value/status/missingness equivalence.

Do not enforce wall-clock thresholds in shared CI. A benchmark smoke test
checks output equivalence only.

Tier 2 cross-language runs additionally require identical deterministic
datasets, declared output tolerances, warmed implementations, matching row
counts, recorded R/Julia runtime details and correctness comparison before any
speed ratio is reported. Include worker startup/orchestration performed within
the public call, while excluding process startup, package loading, compilation,
input parsing and formatting.

## Optimisation policy

The v0.1.0 baseline preserves worker-local fused execution:

```text
solar geometry → meteorological preparation → component solves → output write
```

Post-v0.1 batch execution may prepare cached zenith values before row solving
when repeated timestamps or coordinates justify the additional batch-level
storage. It must preserve missing-time and invalid-coordinate diagnostics,
scalar numerical equivalence and deterministic serial/threaded output.
Retain the prepared pass only when at least one intended repeated/grouped
workload improves materially (approximately 5% or more), unique-key and
four-thread workloads do not regress materially, small-batch overhead remains
acceptable, one-million-row memory is documented and the serial preparation
pass does not dominate the complete call. A change within benchmark noise does
not justify the added buffer and dictionaries.
Residual-overhead reduction, inlining, SIMD and advanced batch solving remain
Tier 2 only. Measure one-thread and multi-thread end-to-end time, allocations,
numerical equivalence and scaling before retaining any of them. Do not use
`@fastmath` in the production scientific path.

## Allocation and quality policy

Review direct scalar physical kernels, scalar value calls and preallocated
batch calls after compilation. Preallocated batch must not allocate replacement
output arrays or public result containers per row; remaining scientific-path
allocations are measured rather than assumed fixed. Keep allocation regression
checks conservative across Julia versions.

Analyse representative released public calls with JET and `@code_warntype`.
Definite runtime dispatch or errors in hot paths are release blockers. Retain
the Julia-only smoke path and do not run cross-language comparison in ordinary
CI.

## Acceptance criteria

### v0.1.0 publication gate

- reproducible Julia scalar and batch harnesses exist and record metadata;
- readability-refactor results are numerically equivalent to the baseline and
  have no material benchmark regression;
- serial/preallocated/threaded paths preserve documented output equivalence;
- JET and allocation review cover released hot paths;
- the small smoke benchmark validates outputs;
- performance documentation is honest about host-specific evidence and makes
  no unsupported HeatStressR ratio claim;
- package remains correct with bounds checks enabled.

### Post-v0.1 completion

- correctness-gated HeatStressR scalar, serial batch and parallel comparisons
  cover the selected fixed, grouped and unique workloads;
- deeper profiling and optimisation decisions cite measured evidence;
- any public cross-language claim has a reproducible committed report;
- no retained optimisation harms numerical correctness or threaded scaling.

## Suggested commits

- `bench: establish Liljegren v0.1 publication baseline`
- `perf: profile and optimise post-v0.1 Liljegren paths`
