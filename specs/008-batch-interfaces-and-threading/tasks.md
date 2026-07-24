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
- [x] Route scalar and batch calls through one typed time/zenith row path; convert
  configuration once per batch and avoid public result materialisation in the
  preallocated value loop.
- [x] Benchmark comparable scalar and batch modes; measure allocation scaling.
- [x] Run the corrected acceptance checks in `quickstart.md`.
- [x] Record final test, benchmark and validation evidence below.

## Evidence

- Evidence: `HEATSTRESS_QUALITY=1 julia --threads=1 --project=. -e 'using
  Pkg; Pkg.test()'` passed the full suite, Aqua and JET (184 batch assertions).
  `HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e
  'using Pkg; Pkg.test()'` passed the complete suite with 185 batch assertions
  and verifies actual multi-thread availability. `.github/workflows/ci.yml`
  now runs complete test jobs at one and four threads, plus a one-thread quality
  job. Coverage includes pre-mutation input/output/alias failure checks,
  arbitrary offset axes, type/missingness policies, independent fixtures and
  every row-varying diagnostic field.

  `julia --threads=4 --project=benchmark benchmark/batch_e2e.jl
  --rows=10000,100000,1000000 --samples=3` measured five equal-input modes:
  public scalar results, public scalar/preallocated outputs, preallocated
  serial batch, allocating serial batch and preallocated threaded batch. At
  one million rows the medians were 4.440 s, 4.348 s, 4.328 s, 4.363 s and
  1.255 s. Preallocated serial allocations were 528 bytes and 14 allocations
  per row plus fixed wrapper overhead. Full host-scoped evidence is in
  `benchmark/README.md`.
- Commit: `6501e11` (`fix: harden batch validation and threading`).
- Commit: `8abe0df` (`refactor: share typed Liljegren row execution`) adds the
  shared isbits typed-row path, worker-local solar computation and the
  five-mode benchmark. `c6ff0cf` (`bench: reuse identical scalar and batch
  inputs`) makes every mode for a row count share the same input arrays.
- Commit: `90ab054` (`fix: validate preallocated batch output length`) adds
  atomic equal-short/equal-long/empty output rejection and all-missing
  numeric-vector equivalence before restoring completion.
