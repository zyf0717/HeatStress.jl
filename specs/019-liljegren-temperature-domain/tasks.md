# Liljegren temperature-domain correction: execution checklist

This checklist records completed v0.3.2 work. Its extrapolation behavior is
superseded by spec 022; the historical test counts below are not evidence for
the v0.5.0 candidate.

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Record the superseded package policy and adjacent-gate audit.
- [x] Replace the Celsius range gate with post-policy Kelvin validation.
- [x] Add positive, finite derived-state validation before component solving.
- [x] Add local input, policy, component-attempt and derived-state regressions.
- [x] Update Liljegren input and provenance documentation.
- [x] Set `Project.toml` and `CITATION.cff` to the v0.3.2 patch release.
- [x] Run focused tests and the full package suite.
- [x] Record validation evidence below.

## Evidence

- Focused validation and scalar tests passed 295 assertions on 2026-08-03:
  `julia --project=. -e 'using Test, HeatStress;
  include("test/test_validation.jl"); include("test/test_liljegren_scalar.jl")'`.
- Full package tests passed 7,233 assertions on 2026-08-03:
  `julia --project=. -e 'using Pkg; Pkg.test()'`.
- No external benchmark or dataset was modified or executed; validation used
  only repository-local tests.
