# Scientific validation hardening: quickstart

```sh
julia --project=validation/high_precision validation/generate_fixture_set_v3.jl --check
julia --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_EXPECT_MULTITHREADED=true julia --threads=4 --project=. -e 'using Pkg; Pkg.test()'
HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```

Any v3 mismatch must identify its row and source. Review the publication,
standalone generator and production implementation before changing a fixture
or tolerance.
