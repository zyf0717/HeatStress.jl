# Scientific fixtures and validation: quickstart

## Workflow

1. Read `spec.md` and all prerequisite units listed in `plan.md`.
2. Complete the unchecked execution items in `tasks.md`.
3. Add source findings and unresolved decisions to `research.md` before changing numerical behavior.
4. Run the validation below and attach evidence to `tasks.md`.

## v0.1 validation

- Run the independent Liljegren scalar and component fixtures offline.
- Compare scalar with allocating, preallocated and threaded batch paths for the
  supported coordinate modes; check values, status and missingness.
- Verify accepted residuals, Float32/Float64 coverage and source provenance for
  every released formula.
- Confirm reports identify the worst row, status and source.

## Post-v0.1 validation

Regenerate secondary-index fixture families deterministically only when their
formulas are selected for a later release. They are not a v0.1 gate.
