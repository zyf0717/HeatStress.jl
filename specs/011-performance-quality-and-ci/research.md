# Liljegren performance benchmarking: research

## Required sources

- Julia performance and threading documentation.
- BenchmarkTools and JET documentation.
- Correctness evidence from the Liljegren slice of 010.
- R timing and parallel-runtime documentation only when a post-v0.1
  cross-language comparison is explicitly scheduled.
- HeatStressR v2.1.6 public documentation only for that optional API
  invocation; its source and benchmark implementation are not design inputs.

The authoritative detail and citations remain in `spec.md`; software implementations are not scientific authorities.

## Findings to record

- Equation, coefficient, policy or design decision.
- Source identifier, section/equation and units.
- Independent validation method and tolerance.

## Open questions

- Set conservative cross-version allocation thresholds.
- Decide profiling evidence required for solar preprocessing or advanced solver work.
- Select cross-implementation tolerances and matched concurrency only for a
  post-v0.1 comparison claim.

## Current harness decision

- Spec 008 supplies the fused worker-local baseline: each row computes solar
  geometry, performs meteorological preparation and component solves, then
  writes output. Its fair Julia comparison uses one deterministic
  structure-of-arrays dataset for public scalar-result, public
  scalar/preallocated-output, preallocated serial batch, allocating batch and
  threaded batch modes. Equality is checked before timing.
- A prepared-zenith experiment is a later profiling decision, not baseline
  preprocessing. If retained, both zenith and solver phases must be parallel;
  its primary number includes both phases end-to-end. Grouped repeated-key work
  must likewise include grouping, key construction and scattering, and avoid a
  shared mutable cache on the hot path.
- The initial scalar harness uses a deterministic fixed-station workload with
  valid floating-point meteorology and all scalar inputs preconstructed. The
  timed function calls `HeatStress.liljegren_wbgt` once per row and materializes
  the full result vector, so scalar preprocessing, solar geometry, component
  solves and result assembly are included. Input creation, warmup, validation
  and report writing are excluded.
- The recorded fused Julia batch baseline is sufficient host-specific v0.1
  performance evidence. A complete profile and correctness-gated comparison
  matrix is post-publication work, not a release blocker.
