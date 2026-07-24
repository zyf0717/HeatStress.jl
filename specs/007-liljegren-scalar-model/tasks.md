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
- [ ] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: package tests cover ordinary, night, zero-wind, saturated,
  dew-point policy, missing/invalid, partial-component, timezone and Float32
  cases; independently sourced scalar fixtures remain owned by spec 010.
- Commit: pending implementation commit
