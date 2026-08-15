# Implementation plan

1. Register the exact primary-source locations and make this unit the active
   correction authority.
2. Add the private bounded Buck kernel and integrate it into Liljegren input
   preparation and wet-bulb residuals.
3. Move wick properties to film-temperature evaluation and correct long-wave,
   irradiance partition and solar-cutoff behaviour.
4. Add boundary and regression tests, then replace high-precision references
   and update their provenance metadata.
5. Rewrite affected specifications and public documentation to current truth,
   update candidate metadata, and run focused/full validation and benchmarks.
