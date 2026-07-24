# Contributing to HeatStress.jl

## Development setup

Use Julia 1.10 or later with the repository environment:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

Run focused tests for changed behaviour and the full suite before proposing a
change. Run quality checks from the test environment and build documentation
from `docs/` when those areas change.

## Scientific and source provenance

Implementations must follow the relevant unit in `specs/`. Record the
published source or original-design rationale for every equation, coefficient,
constant, and policy in `validation/sources.toml`. Do not copy or translate
source, tests, fixtures, documentation, or distinctive structure from
HeatStressR or another implementation.

Contributions are submitted under the MIT License. Contributors must have the
right to submit all code, test data, and documentation they provide.
