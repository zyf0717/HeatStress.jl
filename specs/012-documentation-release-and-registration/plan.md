# Documentation and release readiness: implementation plan

## Dependency gate

009 Other heat indices; complete 010 Scientific fixtures and validation; 011
Liljegren performance benchmarking

## Design

Prepare a transparent MIT Julia package with executable documentation, provenance disclosure and General-registration readiness.
This work resumes only after the spec 011 benchmark findings have been reviewed.

## Sequence

1. Write docs from stable contracts and results.
2. Add citation, license and contribution metadata.
3. Add release-wide Aqua, formatting, coverage, documentation and platform-CI
   quality gates.
4. Build docs without warnings.
5. Run the release-readiness checklist.
6. Freeze the candidate tree for spec 013; after committing it, pass that commit SHA in the audit invocation/evidence. Do not tag, publish or register it here.

## Completion rule

Do not mark this unit complete until every acceptance criterion in `spec.md` passes and the concrete evidence is recorded in `tasks.md`.
