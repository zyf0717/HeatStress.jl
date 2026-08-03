# Wind-height preprocessing: validation quickstart

```sh
julia --project=. test/test_wind_height.jl
julia --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```
