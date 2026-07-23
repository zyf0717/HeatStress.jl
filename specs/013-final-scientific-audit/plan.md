# Final scientific audit and release authorisation: implementation plan

## Dependency gate

012 Documentation and release readiness; all prior units must meet their acceptance criteria

## Design

Audit source provenance, scientific correctness, licensing, quality evidence and one exact release candidate; this unit does not introduce scientific behavior.

## Sequence

1. Complete provenance and independence scans.
2. Generate scientific validation report.
3. Review quality/CI and release-readiness evidence.
4. Record accepted deviations or block release.
5. Create the v0.1.0 decision record and authorise or reject publication of the audited commit.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
