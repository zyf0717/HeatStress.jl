# Constants, units and policies: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Complete the constant/default provenance inventory.
- [x] Create typed constants with source citations.
- [x] Implement Celsius/Kelvin and pressure/radiation unit boundary checks.
- [x] Implement dew-point, wind and radiation validation policies.
- [x] Test tolerance boundaries and missingness behavior.
- [x] Document the public numeric-unit contract.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Integrate `_normalize_basic_meteorology` and `_apply_solar_policy` with the sourced solar-geometry kernel once spec 004 resolves its source-selection gate.
- [x] Add an actual mutating-batch preflight/no-output-mutation test when spec 008 introduces its batch API.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: Public row execution calls the spec-004 sourced solar kernel before
  `_apply_solar_policy`; `test/test_validation.jl` covers its policy boundary.
  `test/test_liljegren_batch.jl` asserts input/output/alias preflight failures
  leave all caller outputs unchanged. Full tests, quality checks and docs passed
  on 2026-07-25.
- Commits: `add549c` implements the constants and input policies; `b87ba0a`
  integrates the sourced solar path; `876be03` completes scalar validation;
  `c315048` records v0.1 release-readiness evidence.
