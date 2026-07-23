# Liljegren scalar model: implementation plan

## Dependency gate

004 Solar geometry and psychrometrics; 005 Physical kernels; 006 Root solving and diagnostics

## Design

Compose validated scalar kernels into globe, natural wet-bulb and complete-WBGT paths while preserving valid component outputs on partial failure.

## Sequence

1. Prepare normalized scalar inputs and solar state.
2. Solve globe and natural-wet-bulb components independently.
3. Compose complete WBGT only from validated components.
4. Expose value-only and diagnostic calls with identical scientific behavior.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
