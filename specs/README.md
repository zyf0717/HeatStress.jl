# HeatStress.jl specification index

This directory is the implementation plan for HeatStress.jl. Work proceeds through the dependency gates below; a unit is complete only when every acceptance criterion in its `spec.md` has evidence recorded in `tasks.md`. Exactly one status must be selected in each `tasks.md`, and this rollup must match it.

## Current delivery focus

The near-term milestone is a correctness-gated performance comparison of the
Liljegren scalar and batch paths against the local HeatStressR v2.1.6 checkout.
Complete only the implementation and independent-validation work needed to
reach spec 011, then use measured profiles and comparisons to choose the next
optimisation work.

Documentation polish, registration readiness, final audit and publication in
specs 012–013 are intentionally deferred. They remain required for a release,
but do not block the benchmark milestone. Secondary indices in spec 009 and
their remaining spec 010 fixtures are also outside the benchmark critical path.

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
| 009 | [Other heat indices](./009-other-heat-indices/) | Planned | 003 Constants, units and policies; Bernard WBGT additionally requires 004 and 006; completion requires 010 validation coverage |
| 010 | [Scientific fixtures and validation](./010-scientific-fixtures-and-validation/) | Planned | 001 Package scaffold; completion requires 004–009 implementations |
| 011 | [Liljegren performance benchmarking](./011-performance-quality-and-ci/) | In progress | 007 Liljegren scalar model; 008 Batch interfaces and threading; independent Liljegren validation evidence from 010 |
| 012 | [Documentation and release readiness](./012-documentation-release-and-registration/) | Planned | 009 Other heat indices; all remaining 010 validation; 011 Liljegren performance benchmarking |
| 013 | [Final scientific audit and release authorisation](./013-final-scientific-audit/) | Planned | 012 Documentation and release readiness; all prior units must meet their acceptance criteria |

The benchmark critical path is `000 → 001 → 002 → 003 → 004/005 → 006 → 007 → 008`, plus the Liljegren validation slice of `010`, then `011`. Unit `009` may proceed independently after `003`, except its Bernard solver work is gated by `004` and `006`. Full completion of `009` and `010` is deferred until the release-readiness path resumes at `012 → 013`.

Release tagging, archival and General registration are post-audit actions. Unit `012` establishes readiness; unit `013` audits one exact candidate source commit. The release tag may point to a subsequent audit-record commit only when its diff contains no source, fixture or scientific-contract change.

## Directory convention

Each numbered unit keeps requirements and execution material together:

- `spec.md` — authoritative requirements, constraints and acceptance criteria migrated from the supplied bundle.
- `plan.md` — local design, dependencies and sequencing.
- `tasks.md` — executable checklist; append evidence and commit hashes here.
- `research.md` — literature, technical findings and unresolved questions.
- `quickstart.md` — validation or usage walkthrough.
- `data-model.md` — present only for structured result types, diagnostics or persisted fixtures.
- `contracts/` — present only for stable public interfaces or fixture schemas.

Do not introduce new top-level specification documents; add material to the relevant numbered unit.

## Suggested implementation PR sequence

| PR | Specs | Required result |
| ---: | --- | --- |
| 1 | 000–001 | charter approval, scaffold, CI and policy documents |
| 2 | 002–003 | API/types/constants/validation |
| 3 | 004 | solar geometry and psychrometrics |
| 4 | 005 | pure physical kernels |
| 5 | 006 | root solver and diagnostics |
| 6 | 007 | scalar Liljegren model |
| 7 | 008 | batch, preallocation and threading |
| 8 | 010 (Liljegren slice) | independent fixtures and validation for the scalar, serial batch and threaded Liljegren paths |
| 9 | 011 | reproducible Julia baselines, correctness-gated HeatStressR v2.1.6 comparison, profiling and measured optimisation |
| 10 | 009 and remaining 010 | selected secondary indices and their independent validation |
| 11 | 012–013 | deferred documentation/readiness, scientific audit and release authorisation |

Fixture schema work from `010` should begin earlier where needed. Stop after the
spec 011 benchmark report to review bottlenecks and reprioritise optimisation
before starting publication polish. Each PR must identify the acceptance
criteria it closes, include relevant tests, update specification evidence,
report commands actually run and avoid exporting incomplete APIs.
