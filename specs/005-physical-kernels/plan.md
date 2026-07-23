# Physical kernels: implementation plan

## Dependency gate

003 Constants, units and policies; 004 supplies solar/psychrometric inputs where composed

## Design

Implement allocation-free scalar heat-transfer and radiation kernels with source-traceable constants and dimensional tests.

## Sequence

1. Transcribe each heat-transfer equation and input units.
2. Implement small scalar kernels independently.
3. Check dimensional/limiting behavior.
4. Integrate only through named residual functions.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
