# Package scaffold: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Create `Project.toml` with a stable UUID and Julia 1.10 compatibility.
- [x] Add the prescribed source, test, docs, benchmark and CI layout.
- [x] Configure initial Ubuntu/Julia 1.10 CI and local Aqua, JET, and documentation validation.
- [x] Add contribution, security, citation and ignore policies.
- [x] Run clean-depot instantiate, precompile and tests.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: Julia 1.10.11; clean depot `/tmp/heatstress-julia-depot.HuYhfo`:
  `using Pkg; Pkg.instantiate(); Pkg.precompile(); Pkg.test()` passed on
  2026-07-24. The CI workflow is one Ubuntu/Julia 1.10 `Pkg.test()` job for
  pushes to `main`. `HEATSTRESS_QUALITY=1 julia --project=. -e 'using Pkg;
  Pkg.test()'` passed Aqua and JET. Documentation built successfully with
  `julia --project=docs docs/make.jl`. The same test, quality, and docs
  commands passed on Julia 1.12.6 (the installed `release` channel).
- Commit: `6ee2c6f` (`chore: scaffold HeatStress Julia package`)
