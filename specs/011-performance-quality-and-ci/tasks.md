# Liljegren performance benchmarking: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [ ] Close the Liljegren correctness prerequisites from specs 007, 008 and 010.
- [ ] Create BenchmarkTools harnesses and deterministic fixed, grouped and
  unique-coordinate datasets.
- [x] Add a Julia-only fixed-station scalar end-to-end harness for 10,000,
  100,000 and 1,000,000 rows.
- [x] Establish the spec-008 identical-input Julia baseline: public scalar
  result and preallocated-output loops, preallocated/allocating serial batch,
  and threaded preallocated batch.
- [ ] Verify the local HeatStressR checkout is v2.1.6 and record both repositories'
  commits and dirty states.
- [ ] Create the ignored local comparison adapter using only public HeatStressR
  APIs.
- [ ] Declare cross-implementation output tolerances and pass the correctness
  gate before timing.
- [ ] Benchmark Julia scalar, serial allocating, serial preallocated and threaded
  paths at the required row sizes.
- [ ] Benchmark corresponding HeatStressR scalar, batch and parallel paths at
  identical row sizes and matched concurrency.
- [ ] Run JET, `@code_warntype`, allocation checks and profiles on Julia hot paths.
- [ ] Optimise only measured bottlenecks, with regression tests, and rerun the
  affected comparison matrix.
- [ ] Add a Julia-only benchmark smoke path without timing thresholds.
- [ ] Record performance environment, timing boundaries, correctness tolerance
  and unresolved discrepancies in the local report.
- [ ] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Julia revision/runtime: scalar harness smoke passed with Julia 1.10.11;
  full-size results are host-specific local evidence.
- HeatStressR revision/dirty state/R runtime: pending
- Benchmark host/concurrency: AMD znver3, Julia 1.10.11, four Julia threads
  for the current spec-008 baseline; one-thread scaling and deeper profiling
  remain pending.
- Correctness gate/tolerances: pending
- Local report: `benchmark/results/scalar-e2e-initial.toml` (ignored local
  evidence; generated 2026-07-24).
- Summary: fixed-station public scalar E2E, three samples: 10,000 rows,
  53.535 ms minimum / 56.999 ms median, 19.2 MB / 1,080,002 allocations;
  100,000 rows, 498.730 ms / 499.018 ms, 192 MB / 10,800,002 allocations;
  1,000,000 rows, 5.272 s / 5.272 s, 1.92 GB / 108,000,002 allocations.
- Post value-materialization separation: ignored local report
  `benchmark/results/scalar-e2e-value-mode.toml`, same host/runtime and
  workload: 10,000 rows, 43.961 ms minimum / 44.801 ms median, 5.92 MB /
  150,002 allocations; 100,000 rows, 441.078 ms / 446.462 ms, 59.2 MB /
  1,500,002 allocations; 1,000,000 rows, 4.452 s / 4.536 s, 592 MB /
  15,000,002 allocations. This is local preliminary evidence only, not a
  cross-language result or scientific correctness gate.
- Current fused baseline: ignored local report
  `benchmark/results/batch-e2e-spec008-typed-row.toml`, with identical
  structure-of-arrays inputs and equality validation for every mode. At one
  million rows, public scalar/preallocated-output and serial preallocated batch
  medians were 4.348 s and 4.328 s; four-thread batch was 1.255 s. The result
  includes all public-call work and is local baseline evidence only. It neither
  benchmarks HeatStressR nor authorizes prepared-zenith/grouped-key work before
  profiling.
- Commit: `8abe0df` (`refactor: share typed Liljegren row execution`) establishes
  the spec-008 baseline consumed by this unit.
- Commit: `c6ff0cf` (`bench: reuse identical scalar and batch inputs`) makes
  that baseline use the same concrete input arrays for every Julia mode.
- Commit: `aab195c` (`perf: add scalar end-to-end benchmark harness`)
