# Liljegren performance benchmarking: implementation plan

## Dependency gate

The v0.1 publication gate depends on 007/008 and the Liljegren validation
slice of 010. Secondary indices, a complete HeatStressR matrix and advanced
optimisation are not prerequisites for release readiness.

## Design

Preserve the completed identical-input Julia baseline: public scalar result
and preallocated-output loops, preallocated serial batch, allocating batch and
threaded batch share one structure-of-arrays dataset and validate equality
before timing. Use this as the v0.1 non-regression reference.

Keep any HeatStressR adapter and raw cross-language output outside the
distributed repository. A reported twofold HeatStressR observation remains a
private advisory finding until reproduced under the Tier 2 correctness gate.

## Sequence

### v0.1 publication gate

1. Re-run the reproducible Julia scalar/batch harnesses after release-scope
   changes and compare with the recorded baseline.
2. Review JET, inference and allocations for released hot paths.
3. Retain a small output-validating benchmark smoke command.
4. Record host-scoped evidence for spec 012 and do not schedule optimisation
   work without a blocker.

### Post-v0.1

1. Profile the fused baseline and identify material bottlenecks.
2. If justified, test parallel prepared-zenith or grouped-key reuse with full
   end-to-end serial/threaded measurements.
3. Verify HeatStressR v2.1.6, build the private public-API adapter and pass the
   correctness gate before any ratio is reported.
4. Retain only measured improvements and update later `0.x` release evidence.

## Completion rule

The v0.1 publication gate may close independently. Full unit completion waits
for any later Tier 2 work deliberately accepted into scope.
