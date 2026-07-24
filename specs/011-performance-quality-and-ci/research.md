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

## Current harness decision

- The initial scalar harness uses a deterministic fixed-station workload with
  valid floating-point meteorology and all scalar inputs preconstructed. The
  timed function calls `HeatStress.liljegren_wbgt` once per row and materializes
  the full result vector, so scalar preprocessing, solar geometry, component
  solves and result assembly are included. Input creation, warmup, validation
  and report writing are excluded.
- Initial one-thread AMD znver3 measurements show approximately linear scalar
  runtime and allocation growth: 53.535 ms/19.2 MB at 10,000 rows, 498.730
  ms/192 MB at 100,000 rows, and 5.272 s/1.92 GB at 1,000,000 rows (minimum
  of three samples). This is baseline evidence only; no optimisation decision
  is made before the required profile and correctness-gated comparison matrix.
