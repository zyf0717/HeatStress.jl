# Solar geometry and psychrometrics: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Resolve the solar-method source/accuracy gate.
- [x] Implement UTC timestamp mode; remove the undocumented date-noon mode.
- [x] Implement `solar_zenith`, vapour pressure and humidity kernels.
- [x] Add below-horizon and leap/calendar boundary tests.
- [x] Add independent numerical fixtures and invariants.
- [x] Document numerical precision and units.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Benchmark fixed-coordinate, repeated-coordinate and unique-coordinate batch workloads.
- [x] Record test and validation evidence and commit SHAs below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` and
  `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'`
  (pass: 184 tests; quality checks pass; 2026-07-24); 15 NREL-SPA fixtures
  have a maximum absolute zenith error of 0.344 degrees and are recorded in
  `research.md`. `julia --project=docs docs/make.jl` also passes. The committed
  scientific corpus adds NREL-SPA cases plus leap/horizon coverage. `julia
  --project=benchmark -e 'include("benchmark/solar_geometry_e2e.jl");
  main(10000)'` passed scalar/batch equivalence for fixed, grouped and unique
  coordinates (0.0019 s smoke measurements on `znver3`).
- Follow-up: `julia --project=benchmark benchmark/solar_geometry_e2e.jl
  --rows=100000 --samples=10` passed scalar/batch equivalence for fixed,
  grouped, unique and grid cardinalities on 2026-09-02. Scalar reference
  generation and equality checks were outside the timed region.
- Commits: `b87ba0a` implements the sourced solar and psychrometric kernels;
  `c315048` records the release-scoped validation and benchmark evidence.
