# Batch interfaces and threading: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Define alignment/broadcasting and output-allocation rules.
- [x] Implement allocating and `!` batch APIs.
- [x] Preserve per-row status, missingness and component values.
- [x] Add thread-safe diagnostics arrays.
- [x] Test fixed, grouped and unique coordinate modes.
- [x] Benchmark before further optimization.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'`
  passed on 2026-07-24 (full suite, Aqua and JET). `julia --threads=2
  --project=. -e 'include("test/test_liljegren_batch.jl")'` passed 38 assertions:
  serial/preallocated/threaded equivalence, fixed/grouped/unique coordinates,
  scalar and aligned secondary inputs, empty/mismatched inputs, output
  validation, diagnostic row alignment, and independent scalar fixture values.
  `julia --threads=2 --project=benchmark benchmark/batch_e2e.jl --rows=10000
  --samples=3` recorded a local preallocated baseline: 0.0455 s serial and
  0.0235 s threaded median. Results remain host-specific local evidence only.
- Commits: `617f945` (`feat: add Liljegren batch execution`); `b028d89`
  (`test: complete batch execution coverage`); `0cbc8b1`
  (`test: validate batch execution against fixtures`).
