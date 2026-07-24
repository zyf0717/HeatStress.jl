# Scientific fixtures and validation: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## v0.1 release slice

- [x] Audit existing independent Liljegren scalar/component/reference/failure
  fixtures and their source identifiers.
- [x] Verify scalar, allocating/preallocated/threaded batch, exact
  status/missingness and diagnostic coverage.
- [x] Verify residual acceptance, Float32/Float64 and applicable fixed/grouped/
  unique-coordinate coverage.
- [x] Confirm provenance for every solar, psychrometric, physical and
  Liljegren formula released in v0.1.0.
- [x] Run the release-slice acceptance checks in `quickstart.md` and record
  evidence.

## Post-v0.1 validation

- [ ] Add secondary-index fixtures only after their formula-selection gate and
  release scope are approved.
- [ ] Extend deterministic generation and mismatch reporting for each future
  fixture family.
- [ ] Record full-unit completion evidence and commit SHA after all selected
  secondary indices are released.

## Evidence

- Evidence: `julia --project=test -e 'using HeatStress, CSV, Dates, Test;
  include("test/test_scientific_validation.jl")'` passed 62 assertions on
  2026-07-25. The committed corpus records NREL-SPA solar authority rows,
  analytic psychrometric/physical rows, standalone 256-bit Liljegren component
  references, failure classifications, residual acceptance, Float32 convergence
  and scalar/fixed/grouped/unique threaded batch equivalence.
- Commit: pending validation commit
