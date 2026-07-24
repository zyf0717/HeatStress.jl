# Physical kernels: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Complete the physical-kernel source-selection table.
- [x] Implement convection, radiation, evaporation and atmospheric terms.
- [x] Keep kernels type-stable and side-effect free.
- [x] Add limiting-case and dimensional tests.
- [x] Record source citations beside each formula family.
- [x] Measure scalar allocations after correctness passes.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` and
  `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'` pass
  (2026-07-24). `test/test_physical_kernels.jl` passes 59 checks: 20+
  property, convection and atmospheric fixtures; 90° direct-beam boundaries;
  independent globe/wet-bulb sign brackets; Float32 inference; and zero
  allocations for repeated residual evaluation after balance construction.
- Commit: pending user review (working tree on `feat/005-physical-kernels`).
