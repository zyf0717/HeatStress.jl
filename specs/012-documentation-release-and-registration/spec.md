# Documentation and release readiness

## Purpose

Prepare a scientifically transparent MIT-licensed Julia package for final audit. This unit establishes release and General-registration readiness; it does not publish the package.

## README structure

1. package status and scope;
2. installation;
3. minimal scalar example;
4. batch/threading example;
5. returned result fields;
6. supported indices and exact formulations;
7. units and timestamp contract;
8. scientific provenance and implementation-independence statement;
9. validation statement and limitations;
10. MIT licence and citation;
11. documentation/build/test badges.

Do not claim equivalence to all Liljegren implementations. State that agreement requires matching pressure, wind treatment, timestamp convention, solar method, radiation partitioning, instrument parameters and numerical policies.

## Documentation pages

### `index.md`

Overview and quick start.

### `api.md`

Public signatures and result types.

### `liljegren.md`

Equations at a conceptual level, source citations, component solving, WBGT composition and configurable physical parameters.

### `inputs.md`

Units, scalar/aligned inputs, timestamp semantics, dewpoint policies, radiation and direct fraction.

### `numerical-behaviour.md`

Bracketing, tolerances, failure reasons, missingness and diagnostic interpretation.

### `performance.md`

Benchmark methodology and results. Public comparisons to other packages must use reproducible public scripts and fair settings.

### `provenance.md`

Include:

- the primary Liljegren paper and supporting sources;
- statement that the Julia source was newly written from literature;
- disclosure that the maintainer previously worked on HeatStressR and may use it privately as advisory comparison;
- statement that no HeatStressR source, comments, tests or fixtures are part of the MIT implementation;
- provenance table for every formula family;
- explanation of independently re-expressed optimisation ideas.

## Docstring examples

Examples must be executable and small. Include scalar, zoned-time and batch examples. Explain that plain `DateTime` is interpreted as UTC if that remains the selected contract.

## Optional R-user correspondence table

A non-normative documentation table may help users find conceptually corresponding functions. Label it **“R-user correspondence,” not “migration mapping.”** It must not claim identical policies or results and must not expose dotted aliases in the Julia API.

## MIT and contribution files

- use the standard MIT licence text without added restrictions;
- identify the copyright holder/year;
- do not require copyright assignment;
- state in `CONTRIBUTING.md` that submitted contributions are MIT-licensed and must have lawful provenance;
- optionally use Developer Certificate of Origin sign-off;
- add no third-party source unless its licence is recorded and compatible.

## Release-readiness checklist

1. specs 000–011 are complete and this unit’s criteria are ready to close;
2. set the candidate version to `0.1.0`;
3. confirm MIT licence, citation and provenance;
4. run tests on all supported platforms;
5. build docs with no warnings;
6. run Aqua/JET;
7. run final scientific validation and save summary;
8. generate benchmark report;
9. review exports and source citations;
10. verify package-name conflict again;
11. configure and validate the intended TagBot, CompatHelper, archival and Registrator workflow without triggering publication;
12. freeze the candidate tree and define the handoff that will pass its post-commit SHA to the final scientific audit.

Tagging, GitHub release creation, archival and registration are post-audit actions governed by spec 013. They are not acceptance criteria for this unit.

## Registration readiness

Confirm:

- the package name is not confusingly close to an existing registered package;
- README/docs clearly identify the scientific formulation and provenance;
- `Project.toml` has compatible lower bounds for every non-stdlib dependency and the repository contains the standard MIT `LICENSE`;
- `[compat]` entries exist for all non-stdlib dependencies;
- tests do not download mutable remote data;
- package loads and tests from a clean depot;
- no GPL or custom-licensed source was accidentally committed;
- generated fixtures contain provenance metadata.

## Acceptance criteria

- primary examples contain no R dependency;
- all exports have docstrings and scientific citations where applicable;
- docs explain numerical failure rather than hiding it;
- provenance accurately describes prior HeatStressR familiarity without presenting HeatStressR as the source;
- release notes describe an independent MIT implementation, not a port;
- no tag, archive, registry submission or other public release action has occurred before spec 013 authorises the candidate commit.

## Suggested commit

`docs: prepare independent MIT implementation for audit`
