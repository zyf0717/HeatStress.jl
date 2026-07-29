# v0.2 scientific audit: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Confirm the exact v0.2 release surface and candidate version.
- [x] Audit formula provenance, contracts and implementation independence.
- [x] Consolidate scientific fixture and boundary-test evidence.
- [ ] Review full/quality/docs/clean-depot/cross-platform evidence.
- [x] Record the exact candidate source commit and permitted audit paths.
- [ ] Record maintainer approval, UTC date and known deviations.
- [x] Verify no publication action occurred.

## Evidence

- Candidate source commit: `4c51b28f53e056bc331c5353f37e574aa62639ef`.
- Permitted post-candidate audit-record paths:
  `specs/015-v020-scientific-audit/tasks.md` and `specs/README.md`.
- Approval: pending
- Local evidence: full suite passed with 85 secondary-measure assertions and
  316 scientific-validation assertions; four-thread suite, Aqua/JET,
  clean-depot install/test, deterministic fixture check and warning-free docs
  passed on Julia 1.10.11.
- Pending: exact candidate SHA, current routine cross-platform CI and explicit
  maintainer approval.
