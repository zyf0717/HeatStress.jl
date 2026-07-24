# Scalar end-to-end benchmark

This harness measures one full public scalar Liljegren calculation per row and
materializes every `WBGTResult`. It excludes deterministic input construction,
compilation warmup, output validation, and report writing from the timed region.

The default workload is a fixed station with 10,000, 100,000, and 1,000,000
ordinary valid rows. It uses three samples per size. Override only for a smoke
run or local investigation:

```sh
julia --project=benchmark -e 'using Pkg; Pkg.develop(PackageSpec(path=".")); Pkg.instantiate()'
julia --project=benchmark benchmark/scalar_e2e.jl
julia --project=benchmark benchmark/scalar_e2e.jl --rows=10000 --samples=10 --output=benchmark/results/scalar-e2e.toml
```

Generated reports are local baseline evidence and ignored by Git. They record
the repository commit/dirty state, UTC timestamp, BenchmarkTools version, and
raw timing samples. This is the scalar fixed-station slice of spec 011, not a
cross-language or batch benchmark; it neither publishes HeatStressR ratios nor
replaces the independent scientific validation gate.
