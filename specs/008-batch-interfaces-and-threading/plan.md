# Batch interfaces and threading: implementation plan

## Dependency gate

007 Liljegren scalar model

## Design

Scale the canonical scalar behavior through ordinary Julia loops, preallocated structure-of-arrays outputs, reusable solar preprocessing and deterministic threading.

## Sequence

1. Implement serial aligned-input batch loop.
2. Implement preallocated `!` path.
3. Add solar-state reuse after profiling evidence.
4. Add threaded scheduling without changing row semantics.
5. Test serial/threaded equivalence.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
