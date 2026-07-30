# Fixture-set v3 data model

## Case definitions

`validation/cases/liljegren-v3.toml` contains only source inputs, factor indices
and policy/configuration selections. Generated numerical expectations are
forbidden in this file.

## Generated fixtures

`validation/fixtures/v3/liljegren_reference.csv` stores inputs, factor indices,
expected input/component statuses, component values, WBGT, validation
residuals, final brackets, authority, source identifier and per-row tolerances.

Focused v3 CSVs store solar, psychrometric, physical-kernel, secondary-index
and failure evidence. Empty numeric fields represent `missing`; statuses use
the exported enum names.

## Metadata

`validation/metadata/fixture-set-v3.toml` records schema version, generator
revision/path, Julia baseline, precision, timezone, deterministic-selection
method, row counts and SHA-256 digests.
