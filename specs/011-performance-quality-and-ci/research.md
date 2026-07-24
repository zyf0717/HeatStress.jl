# Liljegren performance benchmarking: research

## Required sources

- Julia performance and threading documentation.
- BenchmarkTools and JET documentation.
- R timing and parallel-runtime documentation needed to define equivalent timed
  boundaries.
- Correctness evidence from the Liljegren slice of 010.
- HeatStressR v2.1.6 public documentation only for API invocation; its source
  and benchmark implementation are not design inputs.

The authoritative detail and citations remain in `spec.md`; software implementations are not scientific authorities.

## Findings to record

- Equation, coefficient, policy or design decision.
- Source identifier, section/equation and units.
- Independent validation method and tolerance.

## Open questions

- Set conservative cross-version allocation thresholds.
- Decide profiling evidence required for solar preprocessing or advanced solver work.
- Select absolute and relative cross-implementation tolerances after independent
  fixture tolerances are established.
- Decide which matched concurrency levels are meaningful on the benchmark host.
