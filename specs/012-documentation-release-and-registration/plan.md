# Documentation and release readiness: implementation plan

## Dependency gate

Completed v0.1 core evidence through 008; the Liljegren/core validation slice
of 010; the publication gate of 011; and 014 readability refactor. Spec 009,
remaining 010 fixtures and Tier 2 of 011 are post-v0.1 work.

## Design

Prepare executable documentation, provenance disclosure, release-wide quality
evidence and General-registration readiness for the declared Liljegren-first
surface. Do not broaden the release to secondary indices merely because their
source files exist.

## Sequence

1. Make README/docs accurate for scope, examples, units, timestamps, numerical
   failure and limitations.
2. Audit public exports, docstrings, provenance, licence, citation and
   `[compat]` metadata.
3. Configure three routine PR checks: Julia 1.10 with four threads on Linux,
   current Julia with Aqua/JET/docs on Linux, and current Julia on Windows.
   Run clean-depot installation/testing separately from routine CI.
4. Recheck package name and validate Registrator, TagBot and archival
   configuration without publishing.
5. Freeze the candidate tree and hand its post-commit SHA to focused spec 013.

## Completion rule

Do not mark this unit complete until every focused v0.1 acceptance criterion
passes and concrete evidence is recorded in `tasks.md`.
