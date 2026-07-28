# Final scientific audit and release authorisation: quickstart

## Workflow

1. Read `spec.md` and all prerequisite units listed in `plan.md`.
2. Complete the unchecked execution items in `tasks.md`.
3. Add source findings and unresolved decisions to `research.md` before changing numerical behavior.
4. Run the validation below and attach evidence to `tasks.md`.

## v0.1 validation

- Confirm the audit contains only the declared Liljegren-first release surface;
  defer secondary-index rows until those APIs are introduced.
- Run clean-depot tests, Linux/macOS/Windows and threaded CI, docs, Aqua/JET,
  benchmark/allocation review and scoped scientific validation.
- Verify release sign-off includes the exact audited source commit, existing
  validation evidence, approver and permitted audit-record paths; verify the
  resulting release commit diff before tagging it.
