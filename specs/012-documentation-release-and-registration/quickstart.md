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

## Publication workflow

1. Require the final release PR head to pass all mandated checks, then squash
   merge it and record the squash commit SHA.
2. Verify matching versions in `Project.toml` and `CITATION.cff` on that commit.
3. Invoke `@JuliaRegistrator register` on the squash commit. Registrator is
   configured to reject commands in pull-request comments in this repository.
4. Wait for the generated General registry pull request to pass and merge.
5. Verify TagBot creates the version tag at the recorded squash commit and the
   corresponding GitHub release. If its automatic event does not run, manually
   dispatch `.github/workflows/TagBot.yml` from `main`.
