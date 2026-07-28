# Final scientific audit and release authorisation: implementation plan

## Dependency gate

012 Documentation and release readiness plus all evidence in the declared Liljegren-first v0.1 scope: core through 008, Liljegren/core validation slice of 010, publication gate of 011 and 014. Spec 009, remaining 010 and Tier 2 of 011 are not v0.1 prerequisites.

## Design

Audit provenance, scientific correctness, licensing, quality evidence and one exact release candidate without introducing scientific behaviour. The audit table is release-scoped; secondary-index rows are conditional on a future release adding them.

## Sequence

1. Confirm candidate scope and complete provenance/independence scans.
2. Consolidate the existing Liljegren/core scientific validation evidence.
3. Review clean-depot, platform, threaded, Aqua, JET, docs and benchmark evidence for released APIs.
4. Record accepted deviations or block release.
5. Create the v0.1 decision record and authorise or reject publication of the audited commit.

## Completion rule

Do not mark this unit complete until every focused v0.1 acceptance criterion passes and concrete evidence is recorded in `tasks.md`.
