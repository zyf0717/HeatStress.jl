# Project charter: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Approve the scientific authority, v0.1 scope and conformance hierarchy.
- [x] Approve the independent-implementation and licensing boundaries.
- [x] Define the equation/provenance inventory ownership and schema.
- [x] Define and ignore private comparison paths.
- [x] Confirm downstream specifications preserve the charter constraints.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record review evidence and the commit or PR revision below when available.

## Evidence

- Approval: The maintainer explicitly approves the primary scientific source,
  v0.1 scope, conformance hierarchy, independent-source implementation rules,
  and MIT licensing boundaries in `spec.md`.
- Evidence: PR #2 established the initial charter and package scaffold;
  `validation/sources.toml` schema version 2 defines the provenance inventory,
  while `docs/src/provenance.md` and private-path exclusions establish the
  publication and comparison boundaries.
- Reference: PR #2, merged as `557a750` (`chore: implement spec 000 and 001`)
