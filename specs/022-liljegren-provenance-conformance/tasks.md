# Liljegren provenance conformance: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Confirm primary-paper locators and resolve the Buck/no-extrapolation policy.
- [x] Register corrected provenance and supersession relationships.
- [x] Implement the Buck, film-property, long-wave and irradiance corrections.
- [x] Add boundary, diagnostic and numerical regression tests.
- [x] Replace fixtures and record before/after sensitivity evidence.
- [x] Update affected specifications, documentation and release metadata.
- [x] Run focused, full, quality, documentation and reproducibility checks.
- [x] Audit the final candidate head and record evidence.

## Evidence

- The supplied 12-page publisher PDF was inspected directly on 2026-08-15;
  relevant locators are recorded in `research.md`.
- Focused physical-kernel, root-solver and scalar suites passed before the full
  validation run.
- `julia --project=. -e 'using Pkg; Pkg.test()'` passed, including all 5,906
  fixture-set-v3 conformance assertions.
- `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'` passed
  Aqua and JET quality gates in addition to the full suite.
- `HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e
  'using Pkg; Pkg.test()'` passed; the batch suite executed 193 assertions.
- Both fixture generators pass `--check` in their declared environments.
- Documenter passed with its build output redirected to a temporary directory;
  the repository's ignored `docs/build` is pre-existing and root-owned, so the
  unmodified default command cannot clean it in this environment.
- The 10,000-row, three-sample scalar benchmark and before/after allocation
  counts are recorded in `research.md`.
- The local candidate audit is complete. Required PR CI and authorised
  maintainer squash merge remain release-authorization gates; no local
  evidence is represented as satisfying them.
