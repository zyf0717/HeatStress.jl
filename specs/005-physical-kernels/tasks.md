# Physical kernels: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Complete the physical-kernel source-selection table.
- [x] Implement convection, radiation, evaporation and atmospheric terms.
- [x] Keep kernels type-stable and side-effect free.
- [x] Add limiting-case and dimensional tests.
- [x] Record source citations beside each formula family.
- [x] Measure scalar allocations after correctness passes.
- [x] Run the acceptance checks in `quickstart.md`.
- [ ] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: pre-correction evidence superseded; rerun after the residual,
  radians and near-horizon corrections.
- Commit: `955aaed` contains the initial implementation; correction pending.
