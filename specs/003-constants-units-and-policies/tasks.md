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
- [ ] Integrate `_normalize_basic_meteorology` and `_apply_solar_policy` with the sourced solar-geometry kernel once spec 004 resolves its source-selection gate.
- [ ] Add an actual mutating-batch preflight/no-output-mutation test when spec 008 introduces its batch API.
- [ ] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'`, `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'`, and `julia --project=docs docs/make.jl` (all pass; 2026-07-24). Basic meteorology normalization and solar forcing policy are separately tested; public orchestration remains gated on spec 004 solar source selection.
- Commit: pending
