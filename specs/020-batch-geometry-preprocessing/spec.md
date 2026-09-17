# Batch geometry preprocessing

## Purpose

Evaluate whether precomputing repeated UTC-time and coordinate terms improves
complete Liljegren batch execution enough to replace the worker-local fused
baseline. Retain the candidate only if it preserves exact behaviour and passes
the recorded end-to-end performance gate.

## Requirements

- Keep all public APIs, result types and scientific policies unchanged.
- Evaluate a private prepared-zenith candidate across fixed, grouped and unique
  geometry workloads at 100,000 and 1,000,000 rows.
- Require exact scalar/batch and serial/threaded parity before timing.
- Include cache construction, zenith generation, solving and output writes in
  candidate timing.
- Retain the optimisation only when end-to-end benchmarks improve repeated-key
  workloads without materially regressing unique-key workloads, allocations or
  threaded scaling.
- Preserve the released worker-local fused path when the gate is not met.
- Retain reusable benchmark coverage independently of the candidate decision.
- Include a grid workload with very few distinct timestamps and many distinct
  coordinate pairs, matching flattened spatial-raster cardinality.

## Acceptance criteria

- Candidate parity is established before performance comparison.
- Same-host baseline/candidate reports cover fixed and grouped repeated-key
  workloads at 100,000 and 1,000,000 rows.
- The retention decision and measured evidence are recorded.
- Production source and tests remain unchanged when the gate fails.
- The committed benchmark harness reproduces fixed, grouped, unique and grid
  workloads while preserving the historical fixed workload as its default.
- The solar-only harness times only the batch call and reproduces the natural
  Julia equivalents of `(100000, 1, 1)` and `(1, 1, 100000)` cardinalities.

## Non-goals

No public prepared-geometry API, persistent/global cache, solar-model change,
solver change, SIMD, `@fastmath`, cross-language comparison or public
performance claim is introduced.
