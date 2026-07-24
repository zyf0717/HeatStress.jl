# HeatStress.jl

HeatStress.jl is a pre-release Julia package that independently implements
heat-stress models from published literature. The Liljegren outdoor WBGT model
is available for scalar and aligned batch inputs, including optional
row-level diagnostics and threaded batch execution. Other index
implementations remain internal while their formula-selection specifications
are incomplete.

## Development

Julia 1.10 or newer is required. To set up the package environment and run
the test suite:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

See [the specifications](specs/README.md) for implementation status,
[the documentation](docs/src/index.md) for use and architecture, and
[scientific provenance](docs/src/provenance.md) for source policy.
