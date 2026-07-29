# Scientific fixtures and validation: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

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

## v0.2 secondary-measure validation

- [x] Approve the spec 009 formula-selection gate and v0.2 release scope.
- [x] Add independent measured-WBGT, NWS heat-index, Stull and humidex fixtures.
- [x] Add deterministic simple-index generation and worst-row/source mismatch
  reporting.
- [x] Record full-unit completion evidence and commit handoff after the selected
  v0.2 secondary measures are validated.

## Evidence

- Evidence: `julia --project=test -e 'using HeatStress, CSV, Dates, Test;
  include("test/test_scientific_validation.jl")'` passed 62 assertions on
  2026-07-25. The committed corpus records NREL-SPA solar authority rows,
  analytic psychrometric/physical rows, standalone 256-bit Liljegren component
  references, failure classifications, residual acceptance, Float32 convergence
  and scalar/fixed/grouped/unique threaded batch equivalence.
- Commit: pending validation commit
- v0.2 evidence: `validation/fixtures/simple_indices.csv` contains 12 analytic,
  published-example and high-precision rows with source identifiers and
  formula-specific tolerances. `validation/generate_simple_indices.jl --check`
  passes without importing `HeatStress`; the scientific-validation corpus
  passes 316 assertions and reports the worst secondary-measure row/source.
- v0.2 commit: exact candidate source commit is recorded by spec 015 after
  freeze.
