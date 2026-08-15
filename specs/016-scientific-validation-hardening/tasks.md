# Scientific validation hardening: execution checklist

This checklist records the completed original v3 delivery. Spec 022 replaces
the Liljegren v1/v3 expectations under generator revision
`v2-buck-liljegren`; historical assertion counts below are not final-head
v0.5.0 evidence.

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Define assurance boundary, compatibility rules and v3 fixture contract.
- [x] Add deterministic 64-case selection and standalone 256-bit generator.
- [x] Add v3 metadata and generated fixtures without modifying v1/v2.
- [x] Add schema, numerical, failure and deterministic property validation.
- [x] Correct per-row tolerances and complete failure reporting.
- [x] Add CI recomputation, coverage artifact, macOS and main-push validation.
- [x] Resolve local ignored manifests and run all acceptance checks.
- [x] Record evidence and completion status.

## Evidence

- `julia --project=validation/high_precision
  validation/generate_fixture_set_v3.jl --check` passed. Check mode recomputed
  case selection and all generated numerical columns before byte comparison.
- Fixture set v3 contains 64 pairwise-covering Liljegren references, 16 focused
  component rows, 10 failure-taxonomy rows, 15 external solar rows, 16
  psychrometric rows, 12 multi-kernel rows and 24 secondary-index rows.
- `julia --project=. -e 'using Pkg; Pkg.test()'` passed 6,903 assertions,
  including 5,882 v3 schema/numerical/property assertions, on Julia 1.10.11.
- `HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=.
  -e 'using Pkg; Pkg.test()'` passed 6,904 assertions with actual threaded
  execution.
- `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'` passed
  the full suite, Aqua and JET. The equivalent coverage-enabled command also
  passed.
- Coverage artifact generation processed 27 source files and reported 719 of
  729 executable lines hit (98.63%); no percentage gate is imposed.
- `julia --project=docs docs/make.jl` completed without documentation warnings.
- No manifests are tracked by this repository. The ignored local root, test
  and high-precision environments were resolved; subsequent tests emitted no
  stale-manifest warning, and clean CI instantiates from project files.
- Known numerical limit: seven v3 Float32 rows correctly reject one component
  at the `1e-4 K` residual threshold because the nearest representable
  candidate yields `1.07e-4` to `2.75e-4 K`. Float64 accepts all 64 rows; the
  Float32 failed component and complete WBGT remain missing.
