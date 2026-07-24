# Liljegren performance benchmarking: implementation plan

## Dependency gate

007 Liljegren scalar model; 008 Batch interfaces and threading; independent
Liljegren validation evidence from 010. Secondary indices and release readiness
are not prerequisites.

## Design

Establish fair Julia baselines and a black-box comparison against the verified
local HeatStressR v2.1.6 checkout. Use correctness checks before timings and
profiles before optimisation. Keep R adapters and raw cross-language results
outside the distributed repository.

## Sequence

1. Finish independent correctness evidence for the benchmarked Liljegren paths.
2. Create deterministic inputs and reproducible Julia baselines.
3. Verify HeatStressR v2.1.6, record both revisions and implement the private
   public-API adapter.
4. Run correctness gates, then serial and matched-concurrency comparisons.
5. Inspect type stability, allocations and profiles.
6. Optimise only proven Julia bottlenecks and rerun the full comparison matrix.
7. Record the local report and review findings before scheduling specs 009,
   012 or 013.

## Current scoped addition

Add a Julia-only, fixed-station public scalar end-to-end harness for 10,000,
100,000 and 1,000,000 rows. It materializes every scalar result and reports
BenchmarkTools minimum/median time, memory and allocations. It is intentionally
separate from the later correctness-gated batch and HeatStressR matrix.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
