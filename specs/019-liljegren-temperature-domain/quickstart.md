# Liljegren temperature-domain correction: validation

Run the focused policy and scalar regressions:

```sh
julia --project=. -e 'using Test, HeatStress; include("test/test_validation.jl"); include("test/test_liljegren_scalar.jl")'
```

Run the full package suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Confirm that representative temperatures outside `[-40, 50] °C` are
unchanged, both component diagnostics record evaluations, exact absolute zero
is rejected, and invalid derived state remains unattempted.
