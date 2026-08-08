# RCC WBGT estimators: validation

Run focused tests:

```sh
julia --project=. -e 'using Test, HeatStress; include("test/test_rcc_psychrometrics.jl"); include("test/test_rcc_scalar.jl"); include("test/test_rcc_batch.jl")'
```

Regenerate independent fixtures without loading HeatStress:

```sh
julia --project=. validation/generate_rcc_wbgt.jl
```

Run the full and quality suites:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'
```

Confirm source-registry lifecycle consistency, scalar/batch/preallocated
equivalence, exact five-iteration psychrometrics, the 87-degree boundary, and
strictly positive RCCNL wind.
