# Liljegren scalar model: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Implement globe-temperature composition.
- [x] Implement natural-wet-bulb composition.
- [x] Implement scalar result assembly and missingness contract.
- [x] Add component, end-to-end and partial-failure tests.
- [x] Add independent globe, natural-wet-bulb and WBGT regression fixtures.
- [x] Add public-call inference and scalar allocation checks.
- [x] Add invalid coordinate/temperature, direct-solar-clipping and component
  evaluation-count diagnostic regressions.
- [x] Stabilize mixed-precision success and failure result types.
- [x] Use explicit public scalar signatures and documented pressure behavior.
- [x] Make independent fixture generation precision-independent and reproducible.
- [x] Separate value-only result materialization from diagnostics without
  duplicating physics, brackets or acceptance policy.
- [x] Document physical configuration effects.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` passed on 2026-07-24
  (105 scalar-model assertions covering independent fixtures, fresh-process
  precision-independent regeneration, explicit public signatures,
  mixed-precision inference, value/diagnostic equality and a 1 KiB warm value
  allocation ceiling). `HEATSTRESS_QUALITY=1` additionally passed Aqua and
  JET checks; `benchmark/scalar_e2e.jl --rows=100 --samples=1` passed as a
  local metadata-rich smoke run.
- Provenance: `validation/sources.toml` records scalar composition, direct
  fraction, component-retention/missingness, temperature-domain and separate
  horizon/clipping diagnostic policies.
- Commits: `d2edb95` (`feat: implement root solver and scalar Liljegren model`);
  `c59d89c` (`test: add scalar validation fixtures`); current completion fix
  pending commit. The full source-identified fixture corpus remains owned by
  spec 010.
