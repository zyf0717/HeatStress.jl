# Batch interfaces and threading: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Define alignment/broadcasting and output-allocation rules.
- [x] Implement atomic preallocated and input-validation boundaries.
- [x] Preserve and verify complete per-row diagnostics under threading.
- [x] Add one-thread and multithreaded CI coverage.
- [x] Test fixed, grouped, unique and offset-indexed coordinate modes.
- [x] Benchmark comparable scalar and batch modes; measure allocation scaling.
- [x] Run the corrected acceptance checks in `quickstart.md`.
- [x] Record final test, benchmark and validation evidence below.

## Evidence

- Evidence: `HEATSTRESS_QUALITY=1 julia --threads=1 --project=. -e 'using
  Pkg; Pkg.test()'` passed the full suite, Aqua and JET (159 batch assertions).
  `HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e
  'using Pkg; Pkg.test()'` passed the complete suite with 160 batch assertions
  and verifies actual multi-thread availability. `.github/workflows/ci.yml`
  now runs complete test jobs at one and four threads, plus a one-thread quality
  job. Coverage includes pre-mutation input/output/alias failure checks,
  arbitrary offset axes, type/missingness policies, independent fixtures and
  every row-varying diagnostic field.

  `julia --threads=4 --project=benchmark benchmark/batch_e2e.jl
  --rows=10000,100000,1000000 --samples=3` measured identical-input scalar,
  preallocated serial, allocating and threaded modes. At one million rows the
  medians were 4.457 s, 4.471 s, 4.515 s and 1.312 s; preallocated serial
  allocations were 544 bytes and 15 allocations per row plus fixed wrapper
  overhead. Full host-scoped evidence is in `benchmark/README.md`.
- Commit: `6501e11` (`fix: harden batch validation and threading`).
