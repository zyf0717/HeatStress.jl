# v0.2 scientific audit: execution checklist

This is historical v0.2 authorization evidence. Its completed status does not
authorize the spec-022 implementation or replacement fixtures.

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Confirm the exact v0.2 release surface and candidate version.
- [x] Audit formula provenance, contracts and implementation independence.
- [x] Consolidate scientific fixture and boundary-test evidence.
- [x] Review local full/quality/docs/clean-depot evidence and define the
  required cross-platform PR gate.
- [x] Identify the candidate as the final checked audit PR head.
- [x] Record the squash-merge approval rule and known deviations.
- [x] Verify no publication action occurred before approval.

## Evidence

- Candidate and approval record: PR #15. Its final head is the candidate; an
  authorised maintainer's squash merge after all required checks pass is
  approval. GitHub records the exact head, actor, UTC time and squash commit.
- Local evidence: full suite passed with 85 secondary-measure assertions and
  316 scientific-validation assertions; four-thread suite, Aqua/JET,
  clean-depot install/test, deterministic fixture check and warning-free docs
  passed on Julia 1.10.11.
- Known deviation: `Pkg.test()` emits the existing stale test-manifest warning;
  the test suite still passes and this does not affect runtime or scientific
  results.
- Operational note: `main` is not branch-protected, so the maintainer must
  enforce the check gate when merging.
- External merge gate: `Minimum Julia + threads`,
  `Current Julia + quality + docs` and `Windows` must pass on the final PR head,
  which must then be squash-merged without another push. No separate audit
  record commit is required.

## Publication record

- Approval and integration: package PR
  [`#15`](https://github.com/zyf0717/HeatStress.jl/pull/15) passed all three
  required checks and was squash-merged at 2026-07-29 01:42:45 UTC. Its final
  head `9aaed472e77fd135f4ded74bea175fba84c36ba8` and squash commit
  `a53cf6bd1ec394de955ae0a8bd182b9bc5996a31` have identical trees.
- Registration: General PR
  [`#162612`](https://github.com/JuliaRegistries/General/pull/162612) merged at
  2026-07-29 02:11:38 UTC and registered v0.2.0 with tree
  `78f82d5774704109fb0c688f4f6144ba200164c3`.
- Publication: GitHub release
  [`v0.2.0`](https://github.com/zyf0717/HeatStress.jl/releases/tag/v0.2.0) was
  published at 2026-07-29 02:18:45 UTC. The tag resolves to the approved squash
  commit `a53cf6bd1ec394de955ae0a8bd182b9bc5996a31`.
- Registry verification: a temporary Julia environment resolved, installed,
  precompiled and loaded `HeatStress v0.2.0` from General on 2026-07-29 UTC.
