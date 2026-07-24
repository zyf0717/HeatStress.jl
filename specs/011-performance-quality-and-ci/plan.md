# Liljegren performance benchmarking: implementation plan

## Dependency gate

007 Liljegren scalar model; 008 Batch interfaces and threading; independent
Liljegren validation evidence from 010. Secondary indices and release readiness
are not prerequisites.

## Design

Begin from the fair, identical-input spec-008 Julia baseline: public scalar
loops, preallocated serial batch, allocating batch, and threaded batch all use
one structure-of-arrays dataset and validate equality before timing. Then use
profiles to choose deeper work. Keep any black-box HeatStressR adapter and raw
cross-language results outside the distributed repository; that comparison is
not part of the spec-008 baseline.

Preserve worker-local fused execution unless profiling justifies an alternative.
Any prepared-zenith or grouped-key experiment must parallelise material
preprocessing and report complete end-to-end timing as its primary result.

## Sequence

1. Profile the completed fused spec-008 path; inspect type stability and allocations.
2. Identify repeated row and batch invariants.
3. Compare worker-local solar geometry with a parallel prepared-zenith path if
   solar geometry is material; then test grouped repeated-key reuse if justified.
4. Reduce proven row-local residual overhead, consider inlining, and use SIMD
   only for simple preprocessing loops.
5. Create deterministic inputs and retain reproducible Julia baselines.
6. Verify HeatStressR v2.1.6, record both revisions and implement the private
   public-API adapter.
7. Run correctness gates, then serial and matched-concurrency comparisons.
8. Record the local report and review findings before scheduling specs 009,
   012 or 013.

## Current scoped addition

Add a Julia-only, fixed-station public scalar end-to-end harness for 10,000,
100,000 and 1,000,000 rows. It materializes every scalar result and reports
BenchmarkTools minimum/median time, memory and allocations. It is intentionally
separate from the later correctness-gated batch and HeatStressR matrix.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
