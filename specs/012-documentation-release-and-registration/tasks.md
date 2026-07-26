# Documentation and release readiness: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Make README scope, installation, scalar/batch examples, units, timestamp
  semantics, diagnostics, provenance and limitations accurate for v0.1.0.
- [x] Complete API, inputs, numerical-behaviour, performance and provenance
  documentation for the released Liljegren surface.
- [x] Add/verify MIT, citation and contribution material; audit exports,
  docstrings, licences and `[compat]`.
- [ ] Configure and run documentation, Aqua, JET, clean-depot and
  Linux/macOS/Windows (including threaded) quality gates.
- [x] Confirm host-specific benchmark documentation and scoped scientific
  validation evidence; make no unsupported cross-language performance claim.
- [ ] Recheck package-name availability and validate Registrator, TagBot and
  archival workflow without publication.
- [ ] Freeze the candidate tree and define how its post-commit SHA is passed to
  spec 013.
- [ ] Run the acceptance checks in `quickstart.md`.
- [ ] Record release-readiness evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=docs docs/make.jl` passed on 2026-07-25 with
  exported helper API coverage. README and docs now describe the Liljegren-only
  v0.1 scope, executable scalar/batch use, UTC/ZonedDateTime semantics,
  diagnostics/missingness, provenance, limitations and host-specific benchmark
  evidence. MIT text, `CITATION.cff`, `CONTRIBUTING.md`, exports and compat were
  reviewed. Platform/clean-depot and registration checks remain active until CI
  runs for this branch.
- Commit: pending release-readiness commit
