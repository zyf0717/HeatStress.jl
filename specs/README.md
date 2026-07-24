# HeatStress.jl specification index

This directory is the implementation plan for HeatStress.jl. Work proceeds
through the dependency gates below; a unit is complete only when every scoped
acceptance criterion in its `spec.md` has evidence recorded in `tasks.md`.
Exactly one status must be selected in each `tasks.md`, and this rollup must
match it.

## Current delivery focus

Publish the smallest scientifically defensible, useful and maintainable package
first. The immediate milestone is a focused Liljegren-first `v0.1.0`: close
only the remaining Liljegren validation and publication-readiness gaps, audit
one exact candidate, then tag, release and register it in Julia General.

The v0.1.0 release surface is limited to the coherent core already supporting
the Liljegren model:

- solar geometry and model-required psychrometric helpers;
- globe temperature, natural wet-bulb temperature and WBGT;
- scalar value and diagnostic APIs;
- serial allocating, preallocated and threaded batch APIs, including
  diagnostics.

Stull, Bernard, humidex, heat index and other secondary indices are
post-v0.1 functionality. Their implementation, fixtures and formula variants
remain planned work; they do not block registration.

Existing reproducible Julia scalar/batch benchmarks, threading evidence and
the completed readability refactor are sufficient performance evidence for the
initial release. Further optimisation or a complete HeatStressR comparison is
not a publication gate unless a correctness, stability or usability blocker is
found. Maintainer observations of a roughly twofold advantage over optimised
HeatStressR v2.1.6 remain advisory and must not become a public claim without a
reproducible, correctness-gated report in this repository.

## Status legend

- `Planned` — requirements are captured; implementation has not met its acceptance criteria.
- `In progress` — implementation is active; record test/benchmark evidence in that unit’s `tasks.md`.
- `Complete` — all acceptance criteria pass and evidence includes the relevant test or result path plus the commit or PR revision when one exists.

## Dependency order

| ID | Unit | Status | Completion prerequisite |
| --- | --- | --- | --- |
| 000 | [Project charter](./000-project-charter/) | Complete | None; approve this governing specification before implementation. |
| 001 | [Package scaffold](./001-package-scaffold/) | Complete | 000 Project charter approved |
| 002 | [Public API and types](./002-public-api-and-types/) | Complete | 001 Package scaffold |
| 003 | [Constants, units and policies](./003-constants-units-and-policies/) | In progress | 002 Public API and types |
| 004 | [Solar geometry and psychrometrics](./004-solar-geometry-and-psychrometrics/) | In progress | 003 Constants, units and policies |
| 005 | [Physical kernels](./005-physical-kernels/) | In progress | 003 Constants, units and policies; 004 supplies solar/psychrometric inputs where composed |
| 006 | [Root solving and diagnostics](./006-root-solving-and-diagnostics/) | In progress | 005 Physical kernels |
| 007 | [Liljegren scalar model](./007-liljegren-scalar-model/) | Complete | 004 Solar geometry and psychrometrics; 005 Physical kernels; 006 Root solving and diagnostics |
| 008 | [Batch interfaces and threading](./008-batch-interfaces-and-threading/) | Complete | 007 Liljegren scalar model |
| 009 | [Other heat indices](./009-other-heat-indices/) | Planned | Post-v0.1 feature unit; its released formulas require their own 010 validation coverage |
| 010 | [Scientific fixtures and validation](./010-scientific-fixtures-and-validation/) | Planned | v0.1 requires only its Liljegren/core slice; secondary-index validation is post-v0.1 |
| 011 | [Liljegren performance benchmarking](./011-performance-quality-and-ci/) | In progress | v0.1 requires only its publication gate; comparison/optimisation tier is post-v0.1 |
| 012 | [Documentation and release readiness](./012-documentation-release-and-registration/) | Planned | 000–008 release-scope evidence; Liljegren slice of 010; publication gate of 011; 014 |
| 013 | [Final scientific audit and release authorisation](./013-final-scientific-audit/) | Planned | 012 and all declared v0.1 release-scope evidence |
| 014 | [Readability refactor](./014-readability-refactor/) | Complete | Preserves completed 007–008 behaviour; v0.1 readiness input |

The v0.1.0 path is `000–008 → Liljegren/core slice of 010 → publication gate
of 011 → 012 → focused 013 audit → tag, release and General registration`.
The source and contracts completed in 007, 008 and 014 are stable foundations;
this roadmap does not reopen their scientific implementation.

Post-v0.1 work is `009 + remaining 010`, followed by deeper 011 profiling,
cross-language comparisons and optimisation only where profiling justifies it.
Julia follows pre-1.0 versioning: later feature and API growth is released in
appropriately scoped `0.x` versions.

Release tagging, archival and General registration remain post-audit actions.
Unit 012 establishes readiness; unit 013 audits one exact candidate source
commit. The release tag may point to a subsequent audit-record commit only
when its diff contains no source, fixture or scientific-contract change.

## Directory convention

Each numbered unit keeps requirements and execution material together:

- `spec.md` — authoritative requirements, constraints and acceptance criteria migrated from the supplied bundle.
- `plan.md` — local design, dependencies and sequencing.
- `tasks.md` — executable checklist; append evidence and commit hashes here.
- `research.md` — literature, technical findings and unresolved questions.
- `quickstart.md` — validation or usage walkthrough.
- `data-model.md` — present only for structured result types, diagnostics or persisted fixtures.
- `contracts/` — present only for stable public interfaces or fixture schemas.

Do not introduce new top-level specification documents; add material to the
relevant numbered unit.

## Suggested implementation PR sequence

| PR | Specs | Required result |
| ---: | --- | --- |
| 1 | roadmap | publish-first delivery plan and scoped v0.1 release surface |
| 2 | 010 (Liljegren/core slice) | close remaining independent Liljegren validation gaps |
| 3 | 011 (publication gate) | preserve reproducible Julia baselines, quality/allocation review and benchmark smoke coverage |
| 4 | 012 | focused v0.1 documentation, CI and General-registration readiness |
| 5 | 013 | focused final audit and candidate sign-off |
| 6 | release | tag, release and register v0.1.0 after audit authorisation |
| 7 | 009 and remaining 010 | secondary indices and their independent validation for later `0.x` releases |
| 8 | 011 (post-publication tier) | profile-led optimisation and optional reproducible cross-language comparison |

Each PR must identify the acceptance criteria it closes, include relevant
tests, update specification evidence, report commands actually run and avoid
exporting incomplete APIs.
