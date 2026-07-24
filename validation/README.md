# Offline scientific validation

This directory holds the release-scoped, independently generated validation
corpus for the public Liljegren-first API.  It is intentionally separate from
the unit tests that exercise internal implementation details.

Fixture authorities are stated per row: `analytic` is an identity or direct
formula evaluation; `high_precision` is a 256-bit recomputation of the
documented equations; `published_example` is a published solar-geometry
authority; and `invariant` records an expected status or relationship.  The
generator never imports `HeatStress`.

Regenerate the corpus only when an equation, source, or fixture-generator
change is reviewed:

```sh
julia --project=. validation/generate_validation_cases.jl
```

The ordinary test suite reads the committed CSV files and reports the fixture
identifier and largest observed difference on failure.  `sources.toml` maps
every fixture family to its scientific source and generation method; metadata
is intentionally independent of the package revision being tested.
