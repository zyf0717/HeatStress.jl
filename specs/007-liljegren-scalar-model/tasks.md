# Liljegren scalar model: execution checklist

## Status

- [x] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Implement globe-temperature composition.
- [x] Implement natural-wet-bulb composition.
- [x] Implement scalar result assembly and missingness contract.
- [x] Add component, end-to-end and partial-failure tests.
- [x] Add independent globe, natural-wet-bulb and WBGT regression fixtures.
- [x] Add public-call inference and scalar allocation checks.
- [x] Add invalid coordinate/temperature, direct-solar-clipping and component
  evaluation-count diagnostic regressions.
- [x] Document physical configuration effects.
- [ ] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` passed on 2026-07-24
  (64 scalar-model assertions covering independent 256-bit component/WBGT
  fixtures, inference, 4 KiB warm scalar allocation ceiling, ordinary, night,
  zero-wind, saturated, dew-point policy, missing/invalid, clipping,
  partial-component, timezone and Float32 cases). The full source-identified
  fixture corpus remains owned by spec 010.
- Commits: `d2edb95` (`feat: implement root solver and scalar Liljegren model`);
  `e9455fc` (keep incomplete scalar API unexported).
