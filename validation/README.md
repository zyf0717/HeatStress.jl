# Offline scientific validation

This directory holds the release-scoped validation corpus for the public
Liljegren-first API. It is intentionally separate from unit tests that
exercise internal implementation details.

Fixture authorities are stated per row: `analytic` is an identity or direct
formula evaluation; `high_precision` is a standalone 256-bit recomputation or
high-accuracy reference; and `invariant` records an expected relationship or
failure classification. The reference generator never imports `HeatStress`.

`generate_validation_cases.jl` regenerates **only**
`fixtures/liljegren_reference.csv` from the standalone 256-bit source fixture.
It never rewrites solar, psychrometric, physical-kernel, or failure CSVs;
those are independently curated source/invariant records described in
`sources.toml`.

Regenerate the high-precision reference only when its equation, source, or
generator changes under review:

```sh
julia --project=. validation/generate_validation_cases.jl
```

Ordinary tests use check mode, which byte-compares an in-memory regeneration to
the committed reference without modifying any fixture:

```sh
julia --project=. validation/generate_validation_cases.jl --check
```

The ordinary test suite reads committed CSV files and reports the fixture
identifier and largest observed difference on failure. `sources.toml` maps
every fixture family to its scientific source and per-family generation method;
metadata is intentionally independent of the package revision being tested.
