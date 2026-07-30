# Liljegren performance benchmarking: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## v0.1 publication gate

- [x] Add a Julia-only fixed-station scalar end-to-end harness for 10,000,
  100,000 and 1,000,000 rows.
- [x] Establish the identical-input Julia baseline: public scalar result and
  preallocated-output loops, preallocated/allocating serial batch, and
  threaded preallocated batch.
- [x] Re-run release-candidate scalar/batch benchmarks and assess any material
  regression against the recorded baseline.
- [x] Review JET, `@code_warntype` and allocations for released hot paths.
- [x] Retain and run a Julia-only output-validating benchmark smoke path.
- [x] Record host/runtime metadata, timing boundaries and the honest
  host-specific documentation statement.
- [x] Run the publication-gate acceptance checks in `quickstart.md`.

## Deferred comparison and optimisation

These items are not accepted tasks for this completed unit. A future numbered
specification must explicitly scope them before work begins:

- select and pin a reviewed HeatStressR version and both runtime environments;
- build an ignored public-API adapter and deterministic comparison datasets;
- pass declared correctness tolerances before timing or publishing a ratio;
- benchmark matched scalar, batch and parallel workloads;
- profile before proposing production optimisation;
- record reproducible evidence for any public performance claim.

## Evidence

- Julia revision/runtime: scalar harness smoke passed with Julia 1.10.11;
  full-size results are host-specific local evidence.
- Benchmark host/concurrency: AMD znver3, Julia 1.10.11, four Julia threads
  for the recorded baseline.
- Current fused baseline: ignored local report
  `benchmark/results/batch-e2e-spec008-typed-row.toml`, with identical inputs
  and equality validation for every mode. At one million rows, public
  scalar/preallocated-output and serial preallocated batch medians were 4.348 s
  and 4.328 s; four-thread batch was 1.255 s (3.45× serial batch). This is
  sufficient host-scoped v0.1 evidence, not a cross-language claim.
- Scalar local reports: `benchmark/results/scalar-e2e-current.toml` and
  `benchmark/results/scalar-e2e-value-mode.toml`; raw results are local
  baseline evidence only.
- Historical maintainer-reported HeatStressR finding: the Julia implementation
  was approximately twice as fast as a pinned optimised HeatStressR v2.1.6
  checkout. No reproducible, correctness-gated committed report supports an
  exact ratio, so this must not appear in public documentation or release
  claims.
- Commit: `8abe0df` (`refactor: share typed Liljegren row execution`) establishes
  the spec-008 baseline; `c6ff0cf` makes every mode use the same concrete input
  arrays; `aab195c` adds the scalar end-to-end harness.
- Candidate rerun: `julia --threads=4 --project=benchmark benchmark/batch_e2e.jl
  --rows=10000,100000 --samples=3 --output=/tmp/heatstress-v010-batch.toml`
  passed output-equivalence validation on `znver3`, Julia 1.10.11 and
  BenchmarkTools 1.8.0. At 100,000 rows serial preallocated median was 0.468 s
  and threaded preallocated median 0.131 s (3.56×). This is a host-local smoke
  comparison against the established 0.425 s / 0.120 s baseline; it introduces
  no hot-path source change and does not justify a cross-host regression claim.
  The one-million-row rerun is retained as the recorded publication baseline.
- Quality/smoke: `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg;
  Pkg.test()'` and `julia --threads=4 --project=benchmark
  benchmark/batch_e2e.jl --rows=10000 --samples=1` passed on 2026-07-25.
- Completion decision: the publication gate is fully evidenced. Optional
  comparison and optimisation work was not accepted into this unit and must
  use a new numbered specification if scheduled.
