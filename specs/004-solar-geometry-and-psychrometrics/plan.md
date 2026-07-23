# Solar geometry and psychrometrics: implementation plan

## Dependency gate

003 Constants, units and policies

## Design

Implement pure scalar solar-time/zenith and psychrometric kernels from cited equations with explicit timestamp semantics.

## Sequence

1. Select and record solar-geometry literature.
2. Implement scalar time conversion and zenith calculation.
3. Implement vapour-pressure and relative-humidity kernels.
4. Validate against independent fixtures and physical invariants.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
