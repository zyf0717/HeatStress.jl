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

`batch_e2e.jl` measures the preallocated batch API for the representative
876,000-row workload from spec 008.  It measures serial mode and, when Julia
has more than one thread, threaded mode.  It is likewise local evidence only:

```sh
julia --project=benchmark benchmark/batch_e2e.jl
julia --threads=auto --project=benchmark benchmark/batch_e2e.jl --rows=10000 --samples=3 --output=benchmark/results/batch-e2e.toml
```

## Local scaling evidence (2026-07-24)

The following host-specific medians used Julia 1.10.11, BenchmarkTools 1.8.0,
CPU `znver3`, three samples per size, and the preallocated `liljegren_wbgt!`
path. Each thread count was run in a fresh Julia process. They are not portable
performance claims or a Julia-versus-R comparison.

| Julia threads | 10,000 rows | 100,000 rows | 1,000,000 rows | 1M throughput | 1M speedup vs. 1 thread |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 44.1 ms | 441.8 ms | 4.406 s | 227k rows/s | 1.00× |
| 2 | 23.7 ms | 236.4 ms | 2.525 s | 396k rows/s | 1.74× |
| 3 | 17.8 ms | 161.3 ms | 1.696 s | 589k rows/s | 2.60× |
| 4 | 12.8 ms | 124.1 ms | 1.319 s | 758k rows/s | 3.34× |
| 5 | 10.2 ms | 102.9 ms | 1.102 s | 907k rows/s | 4.00× |
| 6 | 9.4 ms | 90.2 ms | 974 ms | 1.03M rows/s | 4.52× |

The same revision's public scalar benchmark was 4.50 s for 1,000,000 rows
(222k rows/s), consistent with the one-thread batch result. The serial batch
path therefore remains computationally equivalent to the scalar loop while
threaded row parallelism provides the observed gain.
