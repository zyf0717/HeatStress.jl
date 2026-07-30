# Fixture-set v3 contract

Every row requires `id`, `authority`, `source_id`, `atol` and `rtol`.
Authorities use the spec 010 vocabulary. Source identifiers must resolve in
`validation/sources.toml`.

Liljegren rows additionally require all public inputs, seven factor indices,
expected `InputStatus`, both expected `FailureReason` values and nullable
component/WBGT values. Accepted components require validation residuals and
ordered final brackets; rejected components require a missing accepted value.

Identifiers are unique within a family. Generated files use UTF-8, LF endings,
stable row order and no locale-dependent formatting.
