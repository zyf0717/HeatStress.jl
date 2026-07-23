# HeatStress.jl specification index

This directory is the implementation plan for HeatStress.jl. Work proceeds in dependency order; a unit is complete only when every acceptance criterion in its `spec.md` has evidence recorded in `tasks.md`.

## Status legend

- `Planned` — requirements are captured; implementation has not met its acceptance criteria.
- `In progress` — implementation is active; record test/benchmark evidence in that unit’s `tasks.md`.
- `Complete` — all acceptance criteria pass and evidence includes the relevant test or result path and commit.

## Dependency order

| ID | Unit | Status | Completion prerequisite |
| --- | --- | --- | --- |
| 000 | [Project charter](./000-project-charter/) | Planned | None; this is the governing specification. |
| 001 | [Package scaffold](./001-package-scaffold/) | Planned | 000 Project charter |
| 002 | [Public API and types](./002-public-api-and-types/) | Planned | 001 Package scaffold |
| 003 | [Constants, units and policies](./003-constants-units-and-policies/) | Planned | 002 Public API and types |
| 004 | [Solar geometry and psychrometrics](./004-solar-geometry-and-psychrometrics/) | Planned | 003 Constants, units and policies |
| 005 | [Physical kernels](./005-physical-kernels/) | Planned | 003 Constants, units and policies; 004 supplies solar/psychrometric inputs where composed |
| 006 | [Root solving and diagnostics](./006-root-solving-and-diagnostics/) | Planned | 005 Physical kernels |
| 007 | [Liljegren scalar model](./007-liljegren-scalar-model/) | Planned | 004 Solar geometry and psychrometrics; 005 Physical kernels; 006 Root solving and diagnostics |
| 008 | [Batch interfaces and threading](./008-batch-interfaces-and-threading/) | Planned | 007 Liljegren scalar model |
| 009 | [Other heat indices](./009-other-heat-indices/) | Planned | 003 Constants, units and policies; completion requires 010 Scientific fixtures and validation |
| 010 | [Scientific fixtures and validation](./010-scientific-fixtures-and-validation/) | Planned | 001 Package scaffold; completion requires 004–009 implementations |
| 011 | [Performance, quality and CI](./011-performance-quality-and-ci/) | Planned | 008 Batch interfaces and threading; 009 Other heat indices; 010 Scientific fixtures and validation |
| 012 | [Documentation, release and registration](./012-documentation-release-and-registration/) | Planned | 011 Performance, quality and CI |
| 013 | [Final scientific audit](./013-final-scientific-audit/) | Planned | 012 Documentation, release and registration; all prior units must meet their acceptance criteria |

The primary execution chain is `000 → 001 → 002 → 003 → 004/005 → 006 → 007 → 008 → 011 → 012 → 013`. Unit `009` may start after `003`, but cannot be completed until `010` validates every index. Unit `010` may establish its fixture schema after `001`; its validation completion depends on the corresponding implemented units.

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
