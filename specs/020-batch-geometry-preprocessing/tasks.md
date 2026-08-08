# Batch geometry preprocessing: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Record requirements, operation-order constraints and retention gates.
- [x] Implement and parity-check the private prepared-geometry candidate.
- [x] Extend the batch benchmark with fixed, grouped and unique workloads.
- [x] Run matched 100,000- and 1,000,000-row baseline/candidate comparisons.
- [x] Reject and remove the candidate after it failed the retention gate.
- [x] Preserve the historical fixed benchmark default.
- [x] Record evidence and synchronize completion status with `specs/README.md`.

## Evidence

- Cached and uncached solar formulas were bit-identical across 8,295 sampled
  time/location combinations before implementation.
- Candidate scalar/batch and serial/threaded parity passed before timing. The
  full package suite also passed 7,379 assertions while the candidate was under
  evaluation.
- Same-host measurements used Julia 1.10.11, four threads and `znver3`.
  Seven-sample 100,000-row fixed medians changed from 0.518 to 0.513 seconds
  preallocated serial, 0.523 to 0.509 seconds allocating serial, and 0.168 to
  0.166 seconds threaded: improvements of 1.0%, 2.7% and 1.2%, below the gate.
- Five-sample 1,000,000-row medians showed no material benefit: fixed
  serial/threaded changed from 5.173/1.662 seconds to 5.302/1.672 seconds;
  grouped changed from 4.851/1.514 seconds to 4.872/1.502 seconds.
- The candidate failed the 5% repeated-key retention gate and was removed.
  Production source and tests match `main`; only reproducible benchmark and
  specification evidence remain.
- `git diff --exit-code HEAD -- src test` and `git diff --check` passed. The
  retained benchmark matrix passed a four-thread smoke run for all three modes:
  `julia --threads=4 --project=benchmark benchmark/batch_e2e.jl
  --geometry=fixed,grouped,unique --rows=1000 --samples=1`. Package tests were
  not rerun after restoring `main` source and tests because the final change is
  limited to benchmark tooling and documentation.
