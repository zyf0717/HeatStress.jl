# Irradiance component inputs: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Define sources, public API, resolution matrix and diagnostics.
- [x] Implement scalar irradiance resolution and breaking v0.3 signatures.
- [x] Implement allocating, preallocated and threaded batch support.
- [x] Add all-combination and independent numerical validation.
- [x] Update public documentation and provenance.
- [x] Run and record full acceptance evidence.

## Evidence

- `test/test_irradiance_inputs.jl` covers all eight presence combinations,
  component identities, fixed and clearness partitioning, closure tolerance
  and rejection, no-input clear sky, TOA-cap isolation, horizon handling,
  Float32, missing row components, offset arrays, and scalar/batch/preallocated
  parity.
- Existing scalar and scientific fixtures are exercised through explicit GHI
  plus `FixedDirectFraction`, preserving their recorded values.
- `julia --project=. -e 'using Pkg; Pkg.test()'` and the same suite under
  `--threads=4` passed on 2026-07-31: 103 focused irradiance assertions and
  the complete existing corpus,
  including 316 scientific-validation and 5,882 v3 conformance assertions.
- `HEATSTRESS_QUALITY=1` passed Aqua and JET checks on the same source tree.
- `julia --project=docs docs/make.jl` and two-row scalar/batch benchmark smoke
  runs passed.
- Documentation, benchmark entry points, version metadata, and
  `validation/sources.toml` use the v0.3 component-aware contract.
