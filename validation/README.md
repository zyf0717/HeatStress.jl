# Offline scientific validation

This directory holds the release-scoped validation corpus for the public
Liljegren and secondary-measure APIs. It is intentionally separate from unit
tests that exercise internal implementation details.

Fixture authorities are stated per row: `analytic` is an identity or direct
formula evaluation; `high_precision` is a standalone 256-bit recomputation or
high-accuracy reference; and `invariant` records an expected relationship or
failure classification. The reference generator never imports `HeatStress`.

`generate_validation_cases.jl` regenerates **only**
`fixtures/liljegren_reference.csv` from the standalone 256-bit source fixture.
It never rewrites solar, psychrometric, physical-kernel, or failure CSVs;
those are independently curated source/invariant records described in
`sources.toml`.

`generate_simple_indices.jl` independently regenerates
`fixtures/simple_indices.csv` at 256-bit precision without importing
`HeatStress`. Its metadata is separate from the frozen v0.1 fixture record.

`generate_rcc_wbgt.jl` independently regenerates `fixtures/rcc_wbgt.csv` at
256-bit precision. It directly evaluates the published NWS psychrometric,
RCC-NWS, RCCNL, Dim228 and Dim167L equations plus both WBGT compositions; it
does not import `HeatStress`.

The fixture-family filenames are stable while their current contents are
replaced in place when an approved scientific correction changes expected
behavior; Git history preserves earlier release evidence. The v2
secondary-measure family is unchanged. Liljegren v1 and v3 revision 2 use
bounded pressure-enhanced Buck psychrometrics, film-temperature wick
properties and the corrected Liljegren radiation assumptions. It
deterministically selects 64 pairwise-covering Liljegren observations and
recomputes their expected components and WBGT directly at 256-bit precision.
It also contains expanded solar, psychrometric, heat-transfer,
secondary-index, and failure-taxonomy fixtures. Neither its case selector nor
its equation evaluator imports `HeatStress`.

Regenerate fixtures only when an equation, source, case definition, or
generator changes under review:

```sh
julia --project=. validation/generate_validation_cases.jl
julia --project=. validation/generate_simple_indices.jl
julia --project=. validation/generate_rcc_wbgt.jl
julia --project=validation/high_precision validation/generate_fixture_set_v3.jl
```

Ordinary tests use check mode, which byte-compares an in-memory regeneration to
the committed reference without modifying any fixture:

```sh
julia --project=. validation/generate_validation_cases.jl --check
julia --project=. validation/generate_simple_indices.jl --check
julia --project=validation/high_precision validation/generate_fixture_set_v3.jl --check
```

The ordinary test suite reads committed CSV files and reports the fixture
identifier, source, complete inputs, expected/actual values, and permitted
tolerance on failure. `sources.toml` maps every fixture family to its scientific
source and per-family generation method; metadata is intentionally independent
of the package revision being tested.
