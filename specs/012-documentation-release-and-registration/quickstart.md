# Documentation and release readiness: quickstart

## Workflow

1. Read `spec.md` and all prerequisite units listed in `plan.md`.
2. Complete the unchecked execution items in `tasks.md`.
3. Add source findings and unresolved decisions to `research.md` before changing numerical behavior.
4. Run the validation below and attach evidence to `tasks.md`.

## v0.1 validation

- Confirm the declared Liljegren-only release surface and that secondary
  indices are excluded from public claims.
- Build docs with scalar, zoned-time and batch examples.
- Run the three routine CI checks: Linux Julia 1.10 with four threads, Linux
  current Julia with Aqua/JET/docs, and Windows current Julia. Run clean-depot
  testing separately as release-readiness validation.
- Audit exports, `[compat]`, MIT/citation/provenance and package-name
  availability.
- Validate Registrator/TagBot workflow without publishing; review every public
  claim against scoped scientific and host-specific performance evidence.
