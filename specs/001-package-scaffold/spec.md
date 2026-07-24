# Package scaffold

## Purpose

Create a conventional Julia package with reproducible tooling before implementing scientific logic.

## Package creation

Use `PkgTemplates.jl` or equivalent tooling. The resulting repository must be named `HeatStress.jl`, but `Project.toml` must use:

```toml
name = "HeatStress"
version = "0.1.0"
```

Generate the UUID once with `UUIDs.uuid4()` and never regenerate it.

## Runtime dependencies

Keep runtime dependencies minimal.

Required initially:

```toml
[deps]
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
TimeZones = "f269a46b-ccf7-5d73-abea-4c690281aa53"
```

Do not add DataFrames, CSV, Roots, StaticArrays, StructArrays, Distributed, Unitful or plotting packages to runtime dependencies during scaffolding.

The root solver is package-owned because the implementation needs deterministic bracketing, evaluation counts, final brackets and failure classifications. Reconsider Roots.jl only if the package-owned solver fails robustness testing.

## Test and development dependencies

Configure test extras or a test project for:

- `Test`
- `Aqua`
- `JET`
- `BenchmarkTools`
- `CSV` only for reading committed scientific fixtures in tests
- `Tables` only if required by CSV fixture loading

Documentation project:

- `Documenter`

Do not make fixture or documentation dependencies runtime dependencies.

## Main module

Create `src/HeatStress.jl` with includes in dependency order. Initially export nothing. Add each public name only when its owning specification is complete and its implementation and docstring exist.

Required include order:

```julia
module HeatStress

using Dates
using TimeZones

include("constants.jl")
include("types.jl")
include("policies.jl")
include("validation.jl")
include("psychrometrics.jl")
include("solar_geometry.jl")
include("heat_transfer.jl")
include("liljegren/residuals.jl")
include("liljegren/root_solver.jl")
include("liljegren/diagnostics.jl")
include("liljegren/globe_temperature.jl")
include("liljegren/natural_wet_bulb.jl")
include("liljegren/scalar.jl")
include("liljegren/batch.jl")
include("indices/stull.jl")
include("indices/bernard.jl")
include("indices/simplified_wbgt.jl")
include("indices/apparent_temperature.jl")
include("indices/effective_temperature.jl")
include("indices/humidex.jl")
include("indices/discomfort_index.jl")
include("indices/heat_index.jl")

# exports grouped here, not scattered through included files

end
```

Empty placeholder files may be created, but no placeholder function may return fabricated numerical results.

## Coding conventions

Mandatory:

- four-space indentation;
- public functions use lower-case snake case;
- types use UpperCamelCase;
- mutating functions end in `!`;
- constants use uppercase names;
- no untyped global mutable state;
- no `Vector{Any}`, dictionaries or named tuples in hot scalar paths;
- no `eval`, generated functions or macros unless justified in a spec amendment;
- public functions have docstrings before export;
- internal names may begin with `_`, but meaningful words are preferred over abbreviations.

## Initial CI scaffold

Create CI before scientific code.

The initial workflow runs only when changes are pushed to `main`. It uses one
`ubuntu-latest` runner with Julia `1.10` and runs instantiation plus
`Pkg.test()`. Aqua, JET, documentation, latest-Julia, and cross-platform CI
remain available as local checks and are deferred as required CI gates to
spec 012.

Tests must not depend on internet access after package instantiation.

## Repository policy files

Create:

- `CONTRIBUTING.md`: development commands, test requirements, source provenance rules.
- `SECURITY.md`: supported versions and disclosure route.
- `.gitignore`: Julia artefacts, coverage output, benchmark temporary files.
- `CITATION.cff`: package author and scientific references, marked as pre-release until v0.1.0.

## Acceptance criteria

- `julia --project -e 'using Pkg; Pkg.instantiate(); Pkg.test()'` passes.
- `using HeatStress` succeeds without warnings.
- Aqua has no stale dependencies, undefined exports or project-file errors.
- CI runs `Pkg.test()` on `ubuntu-latest` with Julia 1.10 for pushes to `main`.
- No scientific function contains placeholder numbers.

## Suggested commit

`chore: scaffold HeatStress Julia package`
