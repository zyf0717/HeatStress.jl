# Public API and types: implementation plan

## Dependency gate

001 Package scaffold

## Design

Define stable scalar, diagnostic and batch APIs using concrete Julia result/configuration types and explicit policy enums.

## Sequence

1. Define enums and validating configuration constructors.
2. Define scalar and batch result/diagnostic structures.
3. Document public signatures and missingness semantics.
4. Add inference and constructor validation tests.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
