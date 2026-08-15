# Final scientific audit and release authorisation: execution checklist

This is immutable evidence of the v0.1 authorization decision. Its completed
status does not authorize the spec-022 implementation or replacement fixtures.

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Confirm the exact Liljegren-first v0.1 release surface and exclude secondary indices from mandatory audit evidence.
- [x] Complete provenance, Liljegren contract and independence checklists for every released formula/API.
- [x] Consolidate existing validation evidence for the released surface.
- [x] Review clean-depot, Linux/macOS/Windows, threaded, Aqua, JET, documentation, allocation and benchmark evidence.
- [x] Scan repository history/source for prohibited provenance.
- [x] Record audited source commit, permitted audit-record paths, known deviations and post-commit diff/tag/release procedure.
- [x] Confirm no listed release-blocking condition remains.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record final evidence and commit SHA below.

## Evidence

- Release surface: Liljegren-first v0.1.0 as declared in `specs/README.md`.
- Primary paper: `10.1080/15459620802310770`.
- Audited and released source commit:
  `c315048dc4ff9b0e1265114f7f6d7b5c9071095c`.
- Permitted post-audit record paths: none; the v0.1.0 tag targets the audited
  source commit directly.
- Validation evidence: `validation/fixtures/`,
  `validation/metadata/fixture-set-v1.toml`, `validation/sources.toml`,
  `test/test_scientific_validation.jl`, and the v0.1 release-slice evidence in
  `specs/010-scientific-fixtures-and-validation/tasks.md`. No standalone
  generated validation report was committed.
- Quality evidence: PR 9 and merge-commit CI passed Linux Julia 1.10/current,
  single/four-thread, macOS, Windows, Aqua/JET, documentation,
  benchmark-output and clean-depot checks. Allocation and host-scoped
  throughput evidence is recorded in
  `specs/011-performance-quality-and-ci/tasks.md`.
- Independence evidence: source/provenance scan passed; the released runtime
  has no R dependency or copied HeatStressR material, and
  `validation/sources.toml` records scientific authorities and generation
  methods.
- Known deviations: no scientific deviation blocks the released scope. The
  standalone report proposed by the original audit template was not created;
  evidence is distributed across the existing paths above. TagBot did not
  publish the release, so the maintainer created it manually.
- Approved by: Yifei Zheng (maintainer).
- Approval/release date: 2026-07-28 UTC.
- Publication evidence: GitHub release `v0.1.0` targets the audited commit;
  Julia General registered HeatStress v0.1.0 in
  `JuliaRegistries/General#162272`.
