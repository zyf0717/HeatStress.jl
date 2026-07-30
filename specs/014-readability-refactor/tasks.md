# Readability refactor: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Add architecture, API, and Liljegren documentation pages and navigation.
- [x] Correct stale package-status wording.
- [x] Audit completed public exports and retain incomplete APIs as internal.
- [x] Remove empty placeholders if present; split type and scalar source files.
- [x] Replace reflective diagnostic copying with explicit assignments.
- [x] Run tests, Aqua, JET, documentation build, and benchmark smoke checks.

## Evidence

- Placeholder audit: `find src -type f -empty` returned no source files.
  Every `include(...)` target at the audited revision contained an
  implementation. Secondary indices were still internal at that revision
  because spec 009 had not yet completed; no non-empty source was removed.
  Spec 009 subsequently completed and released its selected APIs in v0.2.0.
- `julia --project=. -e 'using Pkg; Pkg.test()'` passed: 620 assertions.
- `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'` passed:
  full suite, Aqua, and JET.
- `HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e
  'using Pkg; Pkg.test()'` passed: 621 assertions, including actual threaded
  batch coverage.
- A temporary `git archive HEAD` baseline and the refactored tree produced the
  same ordinary scalar `WBGTResult{Float64}` fields exactly and the same warmed
  direct-call allocation count (720 bytes).
- `julia --project=docs docs/make.jl` completed successfully.
- Scalar and batch BenchmarkTools smoke runs at 10,000 rows / one sample
  completed their built-in value-equivalence checks. Their timings are
  host-local smoke observations only, not regression evidence.
