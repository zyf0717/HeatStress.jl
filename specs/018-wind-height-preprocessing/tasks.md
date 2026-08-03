# Wind-height preprocessing: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Specify the public contract, scientific source and data model.
- [x] Implement standalone preprocessing and diagnostics.
- [x] Integrate all Liljegren scalar and batch entry points.
- [x] Add focused, regression, type and threading tests.
- [x] Update public documentation and provenance.
- [x] Run and record full acceptance evidence.
- [x] Approve spec 018 as the v0.3.1 scientific-audit package and define the
  final-head CI/squash-merge publication gate.

## Evidence

- `test/test_wind_height.jl` passes 156 assertions covering all EPA SRDT cells,
  exact wind/radiation boundaries, terrain exponents, explicit stability,
  power-law values, validation, Float32/BigFloat, floor diagnostics, legacy
  no-op equivalence, scalar/component/batch/preallocated parity, input aliases,
  missing classifier meteorology and serial/threaded equivalence.
- `julia --project=. -e 'using Pkg; Pkg.test()'` passed on 2026-08-03,
  including 5,882 v3 conformance assertions and all existing scientific
  fixtures.
- The same suite passed with `--threads=4` and
  `HEATSTRESS_EXPECT_MULTITHREADED=true` on 2026-08-03.
- `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'` passed
  Aqua and JET checks on 2026-08-03.
- `julia --project=docs docs/make.jl` passed on 2026-08-03.
- `Project.toml` and `CITATION.cff` declare the non-breaking v0.3.1 release.
- Release approval condition: `Minimum Julia + threads`, `Current Julia +
  quality + docs`, `Windows`, and `macOS` must pass on the final PR head, which
  must then be squash-merged by an authorised maintainer without another push.
