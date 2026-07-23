# Other heat indices: implementation plan

## Dependency gate

003 Constants, units and policies; completion requires 010 Scientific fixtures and validation

## Design

Implement cited secondary indices as direct, independently validated formulas with explicit applicability and unit behavior.

## Sequence

1. Record source/formula/provenance for each index.
2. Implement one scalar formula at a time.
3. Add domain and unit tests.
4. Validate each against independent fixtures before declaring completion.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
