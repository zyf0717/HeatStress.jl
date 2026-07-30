# Irradiance component inputs: validation quickstart

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```

Confirm that all eight presence combinations agree with their closure-derived
equivalents and that a no-input daytime call reports estimated clear-sky
irradiance in `diagnose_liljegren(...).irradiance`.
