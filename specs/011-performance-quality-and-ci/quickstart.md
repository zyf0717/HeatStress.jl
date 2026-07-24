# Liljegren performance benchmarking: quickstart

## v0.1 publication validation

1. Run independent Liljegren tests and serial/threaded equivalence checks.
2. Run JET, inference and allocation review for released hot paths.
3. Run the deterministic Julia scalar/batch harnesses and compare their output
   validation and host-scoped measurements with the recorded baseline.
4. Run the Julia-only smoke benchmark; do not treat its wall-clock time as a
   CI threshold.
5. Record exact commands, host/runtime metadata and any regression assessment
   in `tasks.md`.

## Post-v0.1 comparison validation

Only when a cross-language claim or optimisation is proposed: verify
HeatStressR version/revisions, generate identical inputs, pass declared
correctness comparisons, then time scalar/serial/parallel paths. Keep raw
adapters and results out of the repository.
