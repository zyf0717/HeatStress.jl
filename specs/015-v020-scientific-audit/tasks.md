# v0.2 scientific audit: execution checklist

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
- [x] Verify no publication action occurred.

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
