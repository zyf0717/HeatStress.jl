# Performance, quality and CI: implementation plan

## Dependency gate

008 Batch interfaces and threading; 009 Other heat indices; 010 Scientific fixtures and validation

## Design

Use profiling after scientific correctness to eliminate type/heap issues, add reproducible benchmarks and enforce portable quality gates.

## Sequence

1. Establish correct baselines and benchmark metadata.
2. Inspect type stability and allocations.
3. Optimize only proven bottlenecks.
4. Add quality/CI gates and conservative regression tests.
5. Publish methods rather than unstable timing thresholds.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
