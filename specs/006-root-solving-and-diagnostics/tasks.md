# Root solving and diagnostics: execution checklist

## Status

- [x] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Validate and document component bracket, expansion and tolerance defaults.
- [x] Implement package-owned scalar solver.
- [x] Track iterations, evaluations and initial/final brackets.
- [x] Reject non-finite, unbracketed and residual-invalid candidates distinctly.
- [x] Implement diagnostic constructors.
- [x] Add adversarial and convergence tests.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record test, benchmark or validation evidence and commit SHA below.

## Evidence

- Evidence: `julia --project=. -e 'using Pkg; Pkg.test()'` passed on 2026-07-24
  (including 51 root-solver assertions).
- Commit: `d2edb95` (`feat: implement root solver and scalar Liljegren model`)
