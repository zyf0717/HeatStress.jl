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

`batch_e2e.jl` uses one generated structure-of-arrays input fixture for all
four comparable modes: an explicit public scalar row loop, preallocated serial
batch, allocating batch, and (when Julia has multiple threads) preallocated
threaded batch. It validates all component values outside the timed region. It
reports each mode's timing, throughput, bytes and allocations, together with
the host, Julia/BenchmarkTools versions and repository state. It is likewise
local evidence only:

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

This table is batch-only scaling evidence. Use `batch_e2e.jl`, rather than the
separate scalar harness, for direct scalar-versus-batch comparisons because it
uses identical generated inputs and validates equality before timing.

## Comparable local evidence (2026-07-24)

On the same `znver3` host with Julia 1.10.11, BenchmarkTools 1.8.0 and four
available Julia threads, the redesigned harness measured all modes against the
same generated inputs (three samples per size):

| Rows | Scalar row loop | Preallocated batch, serial | Allocating batch | Preallocated batch, 4 threads |
| ---: | ---: | ---: | ---: | ---: |
| 10,000 | 43.9 ms | 43.4 ms | 44.3 ms | 12.3 ms |
| 100,000 | 444.5 ms | 440.4 ms | 444.1 ms | 123.9 ms |
| 1,000,000 | 4.457 s | 4.471 s | 4.515 s | 1.312 s |

At one million rows the corresponding throughput was 224k, 224k, 222k and
762k rows/s. The serial batch wrapper is therefore within measurement noise of
the explicit public scalar loop; its purpose is aligned-array and preallocation
semantics, not a second vector solver. Four-thread execution was 3.40× faster
than the scalar-row control on this host.

Warm preallocated serial calls measured 5,440,288 bytes / 150,011 allocations
at 10,000 rows, 54,400,288 bytes / 1,500,011 allocations at 100,000 rows, and
544,000,288 bytes / 15,000,011 allocations at 1,000,000 rows. This is 544
bytes and 15 allocations per row plus small fixed wrapper overhead. The
allocations come from the canonical scalar value path, not replacement batch
result arrays; preallocated output arrays are allocated outside the timed
region. These measurements define the current contract and identify scalar
materialization as the only justified future allocation optimization target.
