# Batch interfaces and threading: implementation plan

## Dependency gate

007 Liljegren scalar model

## Design

Scale the canonical scalar behavior through a shared typed row path, ordinary
Julia loops, preallocated structure-of-arrays outputs, and deterministic
threading. Scalar and batch boundaries promote values and convert configuration
once before calling the same private time-based row calculation; its
prepared-zenith continuation owns the shared downstream equations. Value-mode
batch loops write the compact internal outcome directly rather than
materializing a public result per row.

v0.1 retains the worker-local per-row solar path. The orchestration thread does
only small validation, configuration and allocation work; grouped-time or
prepared-zenith preprocessing remains a profiled spec-011 optimisation and may
not become a serial O(n) bottleneck.

## Sequence

1. Implement serial aligned-input batch loop and preallocated `!` path.
2. Establish the shared typed time/zenith row calculation and one conversion
   per batch.
3. Remove repeated public-wrapper/result materialisation from value batches.
4. Add threaded scheduling without changing worker-local row semantics.
5. Test scalar/serial/threaded equivalence and benchmark the identical-input
   scalar-preallocated-output control against serial batch.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
