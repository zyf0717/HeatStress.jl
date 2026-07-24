# Performance

The committed v0.1 benchmark evidence is host-specific. On an AMD `znver3`
host with Julia 1.10.11, BenchmarkTools 1.8.0, and four Julia threads, the
one-million-row deterministic fixed-station workload measured median times of
4.328 s for preallocated serial batch and 1.255 s for preallocated threaded
batch (3.45× on that host). Inputs, compilation, validation, and report
writing were outside the timed region; the public calculation itself was not.

These are reproducible local baseline observations, not a universal guarantee
and not a Julia-versus-HeatStressR claim. The benchmark harness validates
scalar, allocating, preallocated, and threaded outputs before timing; shared
CI only runs an output-validating smoke path and never enforces wall-clock
thresholds.

```sh
julia --threads=auto --project=benchmark benchmark/batch_e2e.jl --rows=10000 --samples=3
```
