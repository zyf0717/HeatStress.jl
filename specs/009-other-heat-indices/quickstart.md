# Secondary heat measures: quickstart

## Workflow

1. Read `spec.md` and all prerequisite units listed in `plan.md`.
2. Complete the unchecked execution items in `tasks.md`.
3. Add source findings and unresolved decisions to `research.md` before changing numerical behavior.
4. Run the validation below and attach evidence to `tasks.md`.

## Validation

- Run `julia --project=. -e 'using Pkg; Pkg.test()'`.
- Run the independent simple-index generator in check mode.
- Build documentation with `checkdocs = :exports`.
- Confirm every export has a traceable citation, domain and tolerance.
