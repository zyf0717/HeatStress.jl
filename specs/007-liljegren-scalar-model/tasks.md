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
- [x] Document physical configuration effects.
- [ ] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` passed on 2026-07-24
  (41 scalar-model assertions covering ordinary, night, zero-wind, saturated,
  dew-point policy, missing/invalid, partial-component, timezone and Float32
  cases). Independently sourced scalar fixtures remain owned by spec 010.
- Commits: `d2edb95` (`feat: implement root solver and scalar Liljegren model`);
  `e9455fc` (keep incomplete scalar API unexported).
