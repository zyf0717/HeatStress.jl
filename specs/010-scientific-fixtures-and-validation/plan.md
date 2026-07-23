# Scientific fixtures and validation: implementation plan

## Dependency gate

001 Package scaffold; completion requires 004–009 implementations

## Design

Build deterministic offline fixtures with provenance metadata, high-precision/or analytic authorities and a validation harness that reports worst differences.

## Sequence

1. Define fixture schema and authority levels.
2. Create deterministic generator and metadata.
3. Generate independent component/reference/failure cases.
4. Implement comparison reporting.
5. Require all scientific units to consume fixtures.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
