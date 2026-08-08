# RCC WBGT estimators: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Audit primary sources and resolve model, wind and NWS-scope blockers.
- [x] Register selected source contracts as `specified` before runtime code.
- [x] Implement and validate NWS psychrometric wet bulb.
- [x] Implement and validate RCC-NWS and RCCNL natural wet bulb.
- [x] Implement and validate Dim228 and Dim167L globe temperature.
- [x] Implement named scalar composed models with reusable results.
- [x] Implement aligned allocating and preallocated batches.
- [x] Add independent fixtures and source-registry lifecycle evidence.
- [x] Update public documentation and add the reproducible benchmark.
- [x] Run focused, full and quality suites; record evidence below.

## Evidence

- WP-25-001, Dimiceli and Piltz, and Boyer source audits completed on
  2026-08-08. Runtime implementation had not begun when registry entries were
  promoted to `specified`.
- Independent 256-bit fixture generation covers eight day/night, low/high
  radiation, low-wind, humidity and pressure cases without importing
  `HeatStress`.
- Focused RCC suites passed 166 assertions on 2026-08-08.
- `julia --project=. -e 'using Pkg; Pkg.test()'` passed 7,399 assertions on
  Julia 1.12.6 in the available project container. The repository manifest was
  resolved with Julia 1.10.11. Aqua and JET completed successfully.
- The documentation build completed with `checkdocs = :exports`; only the
  expected edit-link warning was emitted because remote repository context was
  not available inside the container.
- `benchmark/rcc_e2e.jl 100 1` completed as a smoke test. No performance claim
  is inferred from that single-run check.
