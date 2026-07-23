# Documentation and release readiness: implementation plan

## Dependency gate

011 Performance, quality and CI

## Design

Prepare a transparent MIT Julia package with executable documentation, provenance disclosure and General-registration readiness.

## Sequence

1. Write docs from stable contracts and results.
2. Add citation, license and contribution metadata.
3. Build docs without warnings.
4. Run the release-readiness checklist.
5. Freeze the candidate tree for spec 013; after committing it, pass that commit SHA in the audit invocation/evidence. Do not tag, publish or register it here.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
