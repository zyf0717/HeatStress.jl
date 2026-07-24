# Final scientific audit and release authorisation: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

## Tasks

- [x] Confirm the exact Liljegren-first v0.1 release surface and exclude secondary indices from mandatory audit evidence.
- [x] Complete provenance, Liljegren contract and independence checklists for every released formula/API.
- [x] Generate `validation/scientific-validation-report.md` for the released surface.
- [ ] Review clean-depot, Linux/macOS/Windows, threaded, Aqua, JET, documentation, allocation and benchmark evidence.
- [x] Scan repository history/source for prohibited provenance.
- [x] Record audited source commit, permitted audit-record paths, known deviations and post-commit diff/tag/release procedure.
- [ ] Block release on every listed condition.
- [ ] Run the acceptance checks in `quickstart.md`.
- [ ] Record final evidence and commit SHA below.

## Evidence

- Evidence: `validation/scientific-validation-report.md` records the audited
  source candidate `eb7367d70d6a9a2b584c827d8cc30d50903001f8`, committed fixture
  counts/errors, residual/batch/type invariants and an independence scan. The
  report deliberately withholds authorization until CI platform checks and an
  explicit maintainer approval are available.
- Commit: pending audit-evidence commit
