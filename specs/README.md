# HeatStress.jl specification index

This directory is the implementation plan for HeatStress.jl. Work proceeds through the dependency gates below; a unit is complete only when every acceptance criterion in its `spec.md` has evidence recorded in `tasks.md`. Exactly one status must be selected in each `tasks.md`, and this rollup must match it.

## Status legend

- `Planned` — requirements are captured; implementation has not met its acceptance criteria.
- `In progress` — implementation is active; record test/benchmark evidence in that unit’s `tasks.md`.
- `Complete` — all acceptance criteria pass and evidence includes the relevant test or result path plus the commit or PR revision when one exists.

## Dependency order

| ID | Unit | Status | Completion prerequisite |
| --- | --- | --- | --- |
| 000 | [Project charter](./000-project-charter/) | Planned | None; approve this governing specification before implementation. |
| 001 | [Package scaffold](./001-package-scaffold/) | Planned | 000 Project charter approved |
| 002 | [Public API and types](./002-public-api-and-types/) | Planned | 001 Package scaffold |
| 003 | [Constants, units and policies](./003-constants-units-and-policies/) | Planned | 002 Public API and types |
| 004 | [Solar geometry and psychrometrics](./004-solar-geometry-and-psychrometrics/) | Planned | 003 Constants, units and policies |
| 005 | [Physical kernels](./005-physical-kernels/) | Planned | 003 Constants, units and policies; 004 supplies solar/psychrometric inputs where composed |
| 006 | [Root solving and diagnostics](./006-root-solving-and-diagnostics/) | Planned | 005 Physical kernels |
| 007 | [Liljegren scalar model](./007-liljegren-scalar-model/) | Planned | 004 Solar geometry and psychrometrics; 005 Physical kernels; 006 Root solving and diagnostics |
| 008 | [Batch interfaces and threading](./008-batch-interfaces-and-threading/) | Planned | 007 Liljegren scalar model |
| 009 | [Other heat indices](./009-other-heat-indices/) | Planned | 003 Constants, units and policies; Bernard WBGT additionally requires 004 and 006; completion requires 010 validation coverage |
| 010 | [Scientific fixtures and validation](./010-scientific-fixtures-and-validation/) | Planned | 001 Package scaffold; completion requires 004–009 implementations |
| 011 | [Performance, quality and CI](./011-performance-quality-and-ci/) | Planned | 008 Batch interfaces and threading; 009 Other heat indices; 010 Scientific fixtures and validation |
| 012 | [Documentation and release readiness](./012-documentation-release-and-registration/) | Planned | 011 Performance, quality and CI |
| 013 | [Final scientific audit and release authorisation](./013-final-scientific-audit/) | Planned | 012 Documentation and release readiness; all prior units must meet their acceptance criteria |

The main Liljegren chain is `000 → 001 → 002 → 003 → 004/005 → 006 → 007 → 008`. Unit `009` may start after `003`, except its Bernard solver work is gated by `004` and `006`. Unit `010` may establish its schema after `001` and grows alongside `004`–`009`; units `009` and `010` close together once every selected index has validation coverage. Units `008`, `009` and `010` converge at `011 → 012 → 013`.

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
| 8 | 009 | selected secondary indices |
| 9 | 010 | independent fixtures and scientific validation suite |
| 10 | 011 | profiling, optimisation and quality gates |
| 11 | 012–013 | documentation/readiness, scientific audit and release authorisation |

Fixture schema work from `010` should begin before PR 9 where needed. Each PR must identify the acceptance criteria it closes, include relevant tests, update specification evidence, report commands actually run and avoid exporting incomplete APIs.
