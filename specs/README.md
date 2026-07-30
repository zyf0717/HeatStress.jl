# HeatStress.jl specification index

This directory is the implementation plan for HeatStress.jl. Work proceeds
through the dependency gates below; a unit is complete only when every scoped
acceptance criterion in its `spec.md` has evidence recorded in `tasks.md`.
Exactly one status must be selected in each `tasks.md`, and this rollup must
match it.

## Current delivery focus

HeatStress v0.2.0 is registered in Julia General and published. It preserves
the focused v0.1.0 Liljegren-first surface and adds the independently sourced
secondary-measure slice completed by specs 009, 010 and 015. Current work
maintains those released surfaces while deferred measures and profile-led
optimisation remain later work.

The v0.1.0 release surface is limited to the coherent core already supporting
the Liljegren model:

- solar geometry and model-required psychrometric helpers;
- globe temperature, natural wet-bulb temperature and WBGT;
- scalar value and diagnostic APIs;
- serial allocating, preallocated and threaded batch APIs, including
  diagnostics.

Measured-component WBGT, NWS heat index, Stull wet bulb and humidex are the
published v0.2.0 additions. Bernard/simplified WBGT, apparent/effective
temperature, discomfort index and UTCI remain deferred.

Existing reproducible Julia scalar/batch benchmarks, threading evidence and
the completed readability refactor are sufficient performance evidence for the
initial release. Further optimisation or a complete HeatStressR comparison is
not a publication gate unless a correctness, stability or usability blocker is
found. Historical maintainer observations of a roughly twofold advantage over
a pinned optimised HeatStressR v2.1.6 checkout remain advisory and must not
become a public claim without a reproducible, correctness-gated report. Future
comparisons may use any reviewed HeatStressR version but must pin and record its
exact commit and dependency environment.

## Status legend

- `Planned` — requirements are captured; implementation has not met its acceptance criteria.
- `In progress` — implementation is active; record test/benchmark evidence in that unit’s `tasks.md`.
- `Complete` — the repository evidence package is complete. For a merge-gated
  audit, publication authorisation becomes effective only after required CI
  passes on the final PR head and an authorised maintainer squash-merges it.

## Dependency order

| ID | Unit | Status | Completion prerequisite |
| --- | --- | --- | --- |
| 000 | [Project charter](./000-project-charter/) | Complete | None; approve this governing specification before implementation. |
| 001 | [Package scaffold](./001-package-scaffold/) | Complete | 000 Project charter approved |
| 002 | [Public API and types](./002-public-api-and-types/) | Complete | 001 Package scaffold |
| 003 | [Constants, units and policies](./003-constants-units-and-policies/) | Complete | 002 Public API and types |
| 004 | [Solar geometry and psychrometrics](./004-solar-geometry-and-psychrometrics/) | Complete | 003 Constants, units and policies |
| 005 | [Physical kernels](./005-physical-kernels/) | Complete | 003 Constants, units and policies; 004 supplies solar/psychrometric inputs where composed |
| 006 | [Root solving and diagnostics](./006-root-solving-and-diagnostics/) | Complete | 005 Physical kernels |
| 007 | [Liljegren scalar model](./007-liljegren-scalar-model/) | Complete | 004 Solar geometry and psychrometrics; 005 Physical kernels; 006 Root solving and diagnostics |
| 008 | [Batch interfaces and threading](./008-batch-interfaces-and-threading/) | Complete | 007 Liljegren scalar model |
| 009 | [Secondary heat measures](./009-other-heat-indices/) | Complete | Selected v0.2 formulas require their own 010 validation coverage |
| 010 | [Scientific fixtures and validation](./010-scientific-fixtures-and-validation/) | Complete | Liljegren/core and selected v0.2 secondary-measure validation |
| 011 | [Liljegren performance benchmarking](./011-performance-quality-and-ci/) | Complete | Completed v0.1 publication gate; deferred comparison/optimisation requires a new specification |
| 012 | [Documentation and release readiness](./012-documentation-release-and-registration/) | Complete | 000–008 release-scope evidence; Liljegren slice of 010; publication gate of 011; 014 |
| 013 | [Final scientific audit and release authorisation](./013-final-scientific-audit/) | Complete | 012 and all declared v0.1 release-scope evidence |
| 014 | [Readability refactor](./014-readability-refactor/) | Complete | Preserves completed 007–008 behaviour; v0.1 readiness input |
| 015 | [v0.2 scientific audit](./015-v020-scientific-audit/) | Complete | Completed 009 and 010 v0.2 slice; PR CI and authorised squash merge gate |
| 016 | [Scientific validation hardening](./016-scientific-validation-hardening/) | Complete | Additive post-v0.2 numerical-conformance evidence; preserves released APIs and audit records |

The completed v0.1.0 path was `000–008 → Liljegren/core slice of 010 →
publication gate of 011 → 012 → focused 013 audit → tag, release and General
registration`.
The source and contracts completed in 007, 008 and 014 are stable foundations;
this roadmap does not reopen their scientific implementation.

The completed v0.2.0 path was `009 + remaining 010 → v0.2 documentation and
candidate checks → 015 audit package → required PR CI → authorised squash
merge`. Deeper profiling, cross-language comparisons and optimisation remain
optional and require a future numbered specification if scheduled. Julia
follows pre-1.0 versioning: later feature and API growth is released in
appropriately scoped `0.x` versions.

Release tagging and General registration are post-audit actions. Unit 012
established readiness and unit 013 preserves the completed v0.1.0 audit record.
For v0.2 and later, required CI validates the final audit PR head and an
authorised squash merge both approves and integrates that tree. GitHub retains
the checked revision, approver, time and resulting commit; no separate
audit-record commit is required.

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
| 8 | future performance unit | profile-led optimisation and optional reproducible cross-language comparison, only if explicitly scheduled |

Each PR must identify the acceptance criteria it closes, include relevant
tests, update specification evidence, report commands actually run and avoid
exporting incomplete APIs.
