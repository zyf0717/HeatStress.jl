# Documentation and release readiness: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Make README scope, installation, scalar/batch examples, units, timestamp
  semantics, diagnostics, provenance and limitations accurate for v0.1.0.
- [x] Complete API, inputs, numerical-behaviour, performance and provenance
  documentation for the released Liljegren surface.
- [x] Add/verify MIT, citation and contribution material; audit exports,
  docstrings, licences and `[compat]`.
- [x] Configure and run the three routine CI checks (Linux Julia 1.10 with
  threads, Linux current Julia with Aqua/JET/docs, Windows current Julia),
  plus a separate clean-depot release-readiness check.
- [x] Confirm host-specific benchmark documentation and scoped scientific
  validation evidence; make no unsupported cross-language performance claim.
- [x] Recheck package-name availability and validate Registrator, TagBot and
  archival workflow without publication.
- [x] Freeze the candidate tree and define how its post-commit SHA is passed to
  spec 013.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record release-readiness evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=docs docs/make.jl` passed on 2026-07-25 with
  exported helper API coverage. README and docs now describe the Liljegren-only
  v0.1 scope, executable scalar/batch use, UTC/ZonedDateTime semantics,
  diagnostics/missingness, provenance, limitations and host-specific benchmark
  evidence. MIT text, `CITATION.cff`, `CONTRIBUTING.md`, exports and compat
  were reviewed.
- CI evidence: PR 9 and its merge commit passed Linux Julia 1.10/current,
  four-thread, macOS, Windows, Aqua/JET, documentation, benchmark-output and
  clean-depot checks. The routine three-check CI layout was subsequently
  established by PR 10.
- Registration evidence: Julia General accepted HeatStress v0.1.0 in
  `JuliaRegistries/General#162272`; TagBot did not publish the release, so the
  maintainer created the GitHub v0.1.0 release manually.
- Candidate/release commit: `c315048dc4ff9b0e1265114f7f6d7b5c9071095c`
