# Public API and types: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Resolve and document the default dew-point policy.
- [x] Implement policy enums without paired Boolean switches.
- [x] Implement `SolverConfig` and `LiljegrenConfig` validation.
- [x] Implement result and diagnostics type families.
- [x] Add Float32/Float64 construction and inference coverage.
- [x] Keep unimplemented functions unexported.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` — 22 assertions passed on Julia 1.10.11; `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'` also passed (Aqua and JET).
- Commit: `82b1963` (`feat: define native Julia API and result types`), `24a3b92` (`fix: bind batch result element type`)
