# Agent Guide

This repository is `HeatStress.jl`, an independent MIT-licensed Julia implementation of heat-stress models derived from published scientific literature.

## Runtime

* Use the Julia version and dependencies declared in `Project.toml`.
* Run commands with `julia --project=.`.
* Do not rely on globally installed packages or modify `LOAD_PATH`.
* Keep dependencies minimal and update compatibility bounds when dependencies change.

## Specifications

* Treat `specs/` as the source of truth for requirements, scientific provenance, architecture, implementation plans, validation, and tasks.
* Treat `specs/README.md` as the specification index and status rollup.
* Organize substantial work under `specs/[###-feature-slug]/`.
* Use the next available three-digit number and keep feature slugs stable.
* Use the repository’s standard artifacts where applicable:

  * `spec.md` for requirements and acceptance criteria
  * `plan.md` for implementation design and sequencing
  * `research.md` for literature and technical findings
  * `data-model.md` for domain structures
  * `quickstart.md` for validation procedures
  * `contracts/` for explicit interfaces
  * `tasks.md` for executable implementation steps
* Create or update the relevant specification before non-trivial code changes.
* Update affected specification artifacts in the same change when design decisions, requirements, validation, or observed behaviour change.
* Update `specs/README.md` when specification status or cross-feature sequencing changes.
* Keep exactly one status selected in each unit’s `tasks.md`; `specs/README.md` must mirror it.
* Treat `[NEEDS CLARIFICATION: ...]` as a blocker only for the scoped decision and its dependants. Do not implement that behaviour without explicit resolution.
* Treat suggested commit messages and PR groupings as guidance, not acceptance evidence.
* Do not add `.specify/`, slash-command directories, or generated agent scaffolding unless explicitly requested.

## Implementation

* Implement the specifications rather than redefining behaviour in code.
* Prefer idiomatic, type-stable Julia and focused changes over broad rewrites.
* Keep numerical kernels, orchestration, diagnostics, and public APIs appropriately separated.
* Avoid hidden global state, import-time side effects, implicit network access, and unnecessary allocations.
* Do not silently mask invalid inputs or numerical failures.
* Establish correctness before adding threading or performance optimizations.

## Independence and Licensing

* Do not copy or translate HeatStressR source, comments, tests, fixtures, or structure.
* HeatStressR may be used privately only for supplementary numerical or performance comparison.
* Independently express algorithms and optimizations in Julia.
* Do not commit private comparison material or code with incompatible licensing.
* Keep repository code, tests, and documentation compatible with the MIT licence.

## Validation

* Run focused tests for touched behaviour, then the full suite:

  ```sh
  julia --project=. -e 'using Pkg; Pkg.test()'
  ```

* Add regression tests for corrected defects.

* Benchmark material performance changes rather than asserting improvements.

* For documentation-only changes, tests are not required; state that explicitly.

* Set the candidate version consistently in `Project.toml` and `CITATION.cff`
  before final scientific-audit PR checks. The checked final head and resulting
  squash commit must contain that release metadata; do not add a post-audit
  version commit.
* Do not tag, publish, archive or register a release until the final scientific
  audit PR passes its required CI on the final head and an authorised maintainer
  squash-merges it. The successful CI and squash merge are the approval record;
  no follow-up audit commit is required. Any later source, fixture or
  scientific-contract change requires a new audit.
* Trigger Julia Registrator from a comment on the authorised squash commit, not
  from the merged pull request: this repository disables Registrator commands
  in pull-request comments. After the General registry pull request merges,
  verify TagBot creates the version tag at that commit and the GitHub release;
  manually dispatch `.github/workflows/TagBot.yml` only if the automatic event
  does not run.
