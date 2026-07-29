# v0.2 scientific audit and release authorisation

## Purpose

Audit the exact final v0.2.0 PR head after the selected spec 009 secondary
measures and their spec 010 validation are complete. Preserve the completed
v0.1 audit in spec 013 unchanged.

## Release surface

The audit covers the unchanged v0.1 Liljegren/core surface plus:

- measured-component WBGT with and without solar load;
- NWS operational heat index;
- Stull wet-bulb approximation;
- ECCC humidex;
- their public contracts, provenance, fixtures and documentation.

Deferred formula candidates and optional Tier 2 performance work are outside
the audit scope.

## Required audit

- verify every added equation, coefficient and policy against its recorded
  scientific or government authority;
- verify exact public names, units, domain behavior, missing propagation and
  promoted return types;
- verify independent fixture generation does not import `HeatStress` or
  another implementation;
- run focused/full tests, quality checks, warning-free docs, fixture check,
  clean-depot test and the routine cross-platform CI matrix;
- review exports, dependencies, compatibility, licences and package metadata;
- confirm the v0.1 surface and fixtures remain unchanged except for accurate
  documentation of the expanded package scope.

## Decision record

The pull request is the approval record. Before its final CI run, it must
contain the complete audit checklist, fixture metadata, validation evidence and
known deviations. The exact candidate is the final PR head on which every
required check succeeds.

Approval occurs when an authorised maintainer squash-merges that checked head.
GitHub records the checked revision, merge actor, UTC time and resulting squash
commit. No post-candidate audit-record commit is required. A new push or any
source, fixture or scientific-contract change invalidates earlier CI and
approval and must pass the gate again.

The squash commit tree must match the checked PR head tree. This unit does not
authorise a tag, GitHub release, archive or registry action.

## Acceptance criteria

- every released v0.2 formula/API has source, contract and validation evidence;
- all required checks pass for the exact final PR head;
- no unresolved licensing, independence, numerical or documentation blocker
  remains;
- an authorised maintainer squash-merges that checked head;
- no publication action occurs under this unit.

The repository checklist may be marked `Complete` once its evidence package is
merge-ready. Publication authorisation becomes effective only when the CI and
squash-merge conditions above are satisfied.
