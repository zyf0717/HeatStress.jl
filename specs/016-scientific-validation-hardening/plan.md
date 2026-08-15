# Scientific validation hardening: implementation plan

## Dependencies

Build on completed specs 004–010 without changing their runtime contracts.
Preserve specs 013 and 015 as historical release records.

## Sequence

1. Define the v3 case, metadata and fixture schemas.
2. Implement deterministic covering-array selection and standalone 256-bit
   recomputation.
3. Commit v3 fixtures and provenance metadata; later sourced corrections may
   replace them in place under a new specification.
4. Add schema, numerical, failure, cross-path and Halton-property tests.
5. Correct per-row tolerance and worst-case reporting in the existing corpus.
6. Extend CI, resolve manifests and run all acceptance checks.
7. Record evidence and mark this unit complete.

## Failure handling

Treat fixture/generator/production disagreements as defects requiring source
review. Do not relax tolerances or rewrite expected values without a recorded
numerical rationale and reviewed provenance change.
