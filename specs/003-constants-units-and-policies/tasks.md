# Constants, units and policies: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Complete the constant/default provenance inventory.
- [x] Create typed constants with source citations.
- [x] Implement Celsius/Kelvin and pressure/radiation unit boundary checks.
- [x] Implement dew-point, wind and radiation validation policies.
- [x] Test tolerance boundaries and missingness behavior.
- [x] Document the public numeric-unit contract.
- [x] Run the acceptance checks in `quickstart.md`.
- [ ] Integrate `_normalize_meteorology` with the sourced solar-geometry kernel once spec 004 resolves its source-selection gate.
- [ ] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` (pass; 2026-07-24). Solar zenith is deliberately injected into `_normalize_meteorology` until spec 004 selects and implements its sourced solar-position kernel.
- Commit: pending
