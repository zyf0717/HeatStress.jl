# Package scaffold: quickstart

## Workflow

1. Read `spec.md` and all prerequisite units listed in `plan.md`.
2. Complete the unchecked execution items in `tasks.md`.
3. Add source findings and unresolved decisions to `research.md` before changing numerical behavior.
4. Run the validation below and attach evidence to `tasks.md`.

## Validation

- Run `julia --project -e 'using Pkg; Pkg.instantiate(); Pkg.test()'`.
- Run `using HeatStress` and the configured quality jobs.
