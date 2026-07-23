# Data model

Committed validation data are offline, versioned artifacts:

| Artifact | Required fields |
| --- | --- |
| fixture row | source ID, inputs with units, expected values/status, tolerance or authority level |
| metadata TOML | schema version, generator version, source list, generation method and seed where applicable |
| validation report | package commit, fixture version/counts, mismatch counts, error summaries and worst rows |

Generated numerical columns are never manually edited. Fixture rows must be traceable to literature, analytic identities or a documented high-precision method.
