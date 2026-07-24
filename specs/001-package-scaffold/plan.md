# Package scaffold: implementation plan

## Dependency gate

000 Project charter

## Design

Create the conventional Julia package, minimal dependency graph, one-job
Ubuntu/Julia 1.10 CI workflow, and policy files; no scientific placeholder
values. Broader CI quality gates are deferred to spec 012.

## Sequence

1. Generate package metadata and dependency layout.
2. Create module include order and empty implementation files only where needed.
3. Add test, docs and CI projects.
4. Validate clean instantiation and package loading.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
