# Liljegren performance benchmarking: execution checklist

## Status

- [x] Planned
- [ ] In progress
- [ ] Complete

## Tasks

- [ ] Close the Liljegren correctness prerequisites from specs 007, 008 and 010.
- [ ] Create BenchmarkTools harnesses and deterministic fixed, grouped and
  unique-coordinate datasets.
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
- [ ] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Julia revision/runtime: pending
- HeatStressR revision/dirty state/R runtime: pending
- Benchmark host/concurrency: pending
- Correctness gate/tolerances: pending
- Local report: pending
- Summary: pending
- Commit: pending
