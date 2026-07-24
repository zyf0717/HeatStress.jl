# Batch interfaces and threading: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Define alignment/broadcasting and output-allocation rules.
- [x] Implement allocating and `!` batch APIs.
- [x] Preserve per-row status, missingness and component values.
- [x] Add thread-safe diagnostics arrays.
- [ ] Test fixed, grouped and unique coordinate modes.
- [ ] Benchmark before further optimization.
- [ ] Run the acceptance checks in `quickstart.md`.
- [ ] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` and
  `julia --threads=2 --project=. -e 'include("test/test_liljegren_batch.jl")'`
  passed on 2026-07-24 (serial/preallocated/threaded equivalence, scalar and
  aligned broadcast inputs, empty/mismatched inputs, output validation and
  diagnostic row alignment).
- Commit: pending
