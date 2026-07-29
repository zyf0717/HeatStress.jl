# Fixture schema contract

Every fixture file uses stable column names and records enough metadata to reproduce its authority: source ID, normalized inputs, expected output/status and declared comparison tolerance. Fixture metadata identifies schema version, generator revision and generation method.

The validation harness must emit exact status/missingness mismatches and the worst numeric row with its source ID.

`simple_indices.csv` uses a long-form `formula` discriminator with nullable
formula-native input columns. Each row supplies only the inputs required by its
formula and records `expected_value`, `authority`, `source_id`, `atol` and
`rtol`.
