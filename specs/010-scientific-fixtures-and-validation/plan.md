# Scientific fixtures and validation: implementation plan

## Dependency gate

001 Package scaffold. The v0.1 completion slice requires the released core
through 008; full unit completion additionally requires the later secondary
indices in 009.

## Design

Build deterministic offline fixtures with provenance metadata,
high-precision/or analytic authorities and a validation harness that reports
worst differences. First close the Liljegren/core slice for v0.1; append
secondary-index families only when their formulas and release scope are fixed.

## Sequence

1. Verify the existing Liljegren fixtures, source identifiers and coverage
   against the v0.1 release surface.
2. Close missing scalar/batch, status/missingness, residual, type and coordinate
   coverage without changing released behaviour.
3. Record deterministic generation/authority metadata and comparison reporting.
4. Freeze the v0.1 validation evidence for the focused audit.
5. Add secondary-index fixture families only in their post-v0.1 feature PRs.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
