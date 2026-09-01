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

`batch_e2e.jl` supports deterministic fixed, grouped, unique and grid
solar-geometry workloads for five comparable modes: a public scalar loop
retaining `WBGTResult`s, a public scalar loop writing three preallocated
component arrays, preallocated serial batch, allocating serial batch, and (when
Julia has multiple threads) preallocated threaded batch. It validates all
component values outside timed regions. The primary spec-008 comparison is the
public scalar/preallocated output loop against preallocated serial batch. It
reports minimum and median time, throughput, bytes, allocations, raw timing
samples, the host, Julia/BenchmarkTools versions and repository state. Inputs,
compilation, equality validation and report writing are excluded; all work
performed by the public batch call is included. It is local evidence only:

```sh
julia --project=benchmark benchmark/batch_e2e.jl
julia --threads=auto --project=benchmark benchmark/batch_e2e.jl --rows=10000 --samples=3 --output=benchmark/results/batch-e2e.toml
julia --threads=4 --project=benchmark benchmark/batch_e2e.jl --geometry=fixed,grouped,unique,grid --rows=10000,100000 --samples=5
```

The default remains the historical fixed-station workload. Select grouped and
unique modes explicitly with `--geometry` when evaluating geometry-sensitive
changes. `grid` is the ERA5-style cardinality regime: one timestamp and one
distinct coordinate pair per row.

`solar_geometry_e2e.jl` times only `solar_zenith_batch`; scalar reference
generation and equality checks are outside the timed region. Its `fixed` and
`grid` rows are the natural flattened equivalents of `(100000, 1, 1)` and
`(1, 1, 100000)`: distinct timestamps at one location versus one timestamp at
distinct locations. The grouped and unique modes complete the cardinality
matrix:

```sh
julia --project=benchmark benchmark/solar_geometry_e2e.jl --rows=100000 --samples=5
```

`rcc_e2e.jl` provides a smaller scalar/aligned-batch benchmark for RCCD167L
and RCC/NWS, with Liljegren scalar timing included only as algorithmic-cost
context. It validates RCC scalar/batch equality before timing. Arguments are
row count and sample count:

```sh
julia --project=benchmark benchmark/rcc_e2e.jl 100000 5
```

The RCC estimators are non-iterative models, not optimized implementations of
the Liljegren algorithm; timing differences must not be reported as such.

## Comparable local evidence (2026-07-24)

On `znver3` with Julia 1.10.11, BenchmarkTools 1.8.0 and four Julia threads,
the current typed-row baseline used three samples per mode and identical inputs:

| Rows | Scalar results | Scalar → preallocated outputs | Batch preallocated, serial | Batch allocating, serial | Batch preallocated, 4 threads |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10,000 | 43.3 ms | 43.0 ms | 42.3 ms | 42.8 ms | 11.9 ms |
| 100,000 | 428.7 ms | 429.5 ms | 424.7 ms | 425.5 ms | 119.9 ms |
| 1,000,000 | 4.440 s | 4.348 s | 4.328 s | 4.363 s | 1.255 s |

At one million rows, the primary serial control and preallocated batch reached
230k and 231k rows/s respectively; this is no material regression. Four-thread
batch reached 797k rows/s (3.45× serial batch). Warm
preallocated serial calls measured 528 bytes and 14 allocations per row plus
small fixed batch overhead; replacement output arrays are allocated outside the
timed region. These host-specific results are neither a Julia-versus-HeatStressR
comparison nor a scientific correctness gate.
