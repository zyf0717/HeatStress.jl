# Root solving and diagnostics: implementation plan

## Dependency gate

005 Physical kernels

## Design

Provide one safeguarded scalar bracketed solver with independent residual validation and structured, reproducible diagnostics.

## Sequence

1. Specify bracket and stopping rules.
2. Implement finite-residual and sign-change checks.
3. Implement safeguarded iteration and residual validation.
4. Map all exits to diagnostics and test each branch.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
