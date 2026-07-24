# Validation

Run the complete package and quality suite:

```sh
HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'
```

Build documentation:

```sh
julia --project=docs docs/make.jl
```

Run small scalar and batch benchmark smoke cases. These validate result
equivalence only; they are not performance evidence:

```sh
julia --project=benchmark benchmark/scalar_e2e.jl --rows=10000 --samples=1
julia --project=benchmark benchmark/batch_e2e.jl --rows=10000 --samples=1
```
