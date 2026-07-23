# Fixture schema contract

Every fixture file uses stable column names and records enough metadata to reproduce its authority: source ID, normalized inputs, expected output/status and declared comparison tolerance. Fixture metadata identifies schema version, generator revision and generation method.

The validation harness must emit exact status/missingness mismatches and the worst numeric row with its source ID.
