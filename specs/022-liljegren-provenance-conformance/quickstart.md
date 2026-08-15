# Validation quickstart

```sh
julia --project=. validation/generate_validation_cases.jl --check
julia --project=validation/high_precision validation/generate_fixture_set_v3.jl --check
julia --project=. -e 'using Pkg; Pkg.test()'
```

Verify diagnostic boundary cases separately: dew points immediately outside
`[-40, 50]` must be `InvalidDomain`; exact endpoints must enter component
solving; and an unbracketable bounded wick root must be `Unbracketed` without
discarding an independently converged globe result.
