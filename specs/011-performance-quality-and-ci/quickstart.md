# Liljegren performance benchmarking: quickstart

## Workflow

1. Read `spec.md` and all prerequisite units listed in `plan.md`.
2. Complete the unchecked execution items in `tasks.md`.
3. Add source findings and unresolved decisions to `research.md` before changing numerical behavior.
4. Run the validation below and attach evidence to `tasks.md`.

## Validation

- Verify `../HeatStressR/DESCRIPTION` declares version `2.1.6`; record both Git
  revisions, dirty states and runtime versions.
- Run independent Liljegren tests, bounds-checked correctness and
  serial/threaded equivalence before comparison.
- Generate the deterministic exchange dataset outside timed regions.
- Warm both implementations, run the correctness gate, then run scalar, serial
  batch and matched-concurrency benchmarks for fixed, grouped and unique
  coordinate modes.
- Run JET, `@code_warntype`, allocation checks and profiles on Julia hot paths.
- Save raw local results under `local-comparison/` and record the milestone
  summary in `tasks.md`.
