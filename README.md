# HeatStress.jl

HeatStress.jl is a pre-release Julia package for independently implementing
heat-stress models from published literature. The package scaffold is in
place; scientific calculation APIs will be added only with their documented
provenance, validation evidence, and completed specifications.

## Development

Julia 1.10 or newer is required. To set up the package environment and run
the test suite:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

See [the specifications](specs/README.md) for the implementation sequence and
[scientific provenance](docs/src/provenance.md) for source policy.
