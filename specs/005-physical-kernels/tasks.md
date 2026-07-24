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

- Evidence: `test/test_physical_kernels.jl` covers independently retained
  air-property/convection/residual values, horizon policy, Float32 inference
  and zero-allocation residual calls. The physical rows in
  `validation/fixtures/physical_kernels.csv` are independently evaluated from
  cited equations; full tests and quality checks passed on 2026-07-25.
- Commit: pending v0.1 readiness commit; initial implementation `955aaed`.
