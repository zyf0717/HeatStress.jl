# Solar geometry and psychrometrics: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Resolve the solar-method source/accuracy gate.
- [x] Implement UTC timestamp mode; remove the undocumented date-noon mode.
- [x] Implement `solar_zenith`, vapour pressure and humidity kernels.
- [x] Add below-horizon and leap/calendar boundary tests.
- [x] Add independent numerical fixtures and invariants.
- [x] Document numerical precision and units.
- [x] Run the acceptance checks in `quickstart.md`.
- [ ] Benchmark fixed-coordinate, repeated-coordinate and unique-coordinate batch workloads.
- [x] Record test and validation evidence below; commit SHA remains pending.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` and
  `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'`
  (pass: 184 tests; quality checks pass; 2026-07-24); solar fixtures
  independently checked against the NOAA Solar Position Calculator and
  recorded in `research.md`. `julia --project=docs docs/make.jl` also passes.
- Commit: pending
