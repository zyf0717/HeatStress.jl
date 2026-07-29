# v0.2 scientific audit and release authorisation

## Purpose

Audit one exact v0.2.0 candidate source commit after the selected spec 009
secondary measures and their spec 010 validation are complete. Preserve the
completed v0.1 audit in spec 013 unchanged.

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

Record the exact audited source commit, fixture metadata, validation evidence,
known deviations, approver and UTC date. Any subsequent source, fixture or
scientific-contract change invalidates the audit.

An audit-record commit after the source freeze may change only the paths
explicitly authorised by the decision record. This unit does not authorise a
tag, GitHub release, archive or registry action.

## Acceptance criteria

- every released v0.2 formula/API has source, contract and validation evidence;
- all required checks pass for the exact candidate revision;
- no unresolved licensing, independence, numerical or documentation blocker
  remains;
- the maintainer approves the recorded candidate;
- no publication action occurs under this unit.
