# Scientific provenance

HeatStress.jl is an independent source implementation from published
literature. It is not a migration or translation of HeatStressR, the Argonne C
implementation, or any other software implementation.

The primary source for the outdoor Liljegren WBGT model is:

> Liljegren, J. C., Carhart, R. A., Lawday, P., Tschopp, S., & Sharp, R.
> (2008). Modeling the Wet Bulb Globe Temperature Using Standard
> Meteorological Measurements. *Journal of Occupational and Environmental
> Hygiene*, 5(10), 645–655. https://doi.org/10.1080/15459620802310770

Every implemented equation, coefficient, physical constant, and model policy
will be linked to the source inventory in `validation/sources.toml` or marked
as an original numerical or API design decision. Cross-implementation results
are advisory validation evidence, never scientific authority.
