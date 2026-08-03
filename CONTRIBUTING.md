# Contributing to HeatStress.jl

## Development setup

Use Julia 1.10 or later with the repository environment:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

Run focused tests for changed behaviour and the full suite before proposing a
change. Run quality checks from the test environment and build documentation
from `docs/` when those areas change.

```sh
HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```

## Scientific and source provenance

Implementations must follow the relevant unit in `specs/`. Record the
published source or original-design rationale for every equation, coefficient,
constant, and policy in `validation/sources.toml`. Do not copy or translate
source, tests, fixtures, documentation, or distinctive structure from
HeatStressR or another implementation.

Contributions are submitted under the MIT License. Contributors must have the
right to submit all code, test data, and documentation they provide.

## Publishing an authorised release

Publish only after the release PR passes its required checks on the final head
and an authorised maintainer squash-merges it. Verify that `Project.toml` and
`CITATION.cff` contain the same version, and record the squash commit SHA.

This repository disables Julia Registrator commands in pull-request comments.
Invoke Registrator in a comment on the squash commit instead; this also pins the
registration to the reviewed tree. Include release notes in the initial command
when they are available:

```sh
release_sha=<squash-commit-sha>
gh api "repos/zyf0717/HeatStress.jl/commits/${release_sha}/comments" \
  --method POST \
  -f body=$'@JuliaRegistrator register\n\nRelease notes:\n\n<release notes>'
```

Wait for Registrator's General registry pull request to pass and merge. The
registry merge prompts Julia TagBot through the configured
`.github/workflows/TagBot.yml`; verify that the resulting version tag targets
the recorded squash commit and that the matching GitHub release exists. If the
automatic TagBot event does not run, dispatch the TagBot workflow manually from
`main`. Do not create or move a release tag before the registry pull request is
merged.
