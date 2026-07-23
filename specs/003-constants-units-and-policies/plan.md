# Constants, units and policies: implementation plan

## Dependency gate

002 Public API and types

## Design

Centralize units, constants, public-boundary validation and meteorological input policies so physical kernels remain pure.

## Sequence

1. Build the provenance table for constants and conversions.
2. Implement input normalization and policy resolution.
3. Test valid, missing and invalid domain paths.
4. Expose no implicit unit conversions.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
