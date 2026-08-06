# Batch geometry preprocessing: quickstart

```sh
julia --threads=4 --project=benchmark benchmark/batch_e2e.jl \
  --geometry=fixed,grouped,unique \
  --rows=10000,100000,1000000 \
  --samples=5
```

Compare baseline and candidate reports on the same host and Julia environment.
Retain the refactor only when fixed and grouped workloads improve by at least
5% at 100,000 and 1,000,000 rows, no workload regresses by more than 5%, and
four-thread scaling falls by no more than 5%.

The recorded candidate failed this gate and is not present in production
source. Use the command to evaluate future geometry-sensitive candidates
against the unchanged fused baseline.
