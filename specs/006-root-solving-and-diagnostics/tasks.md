# Root solving and diagnostics: execution checklist

## Status

- [ ] Planned
- [x] In progress
- [ ] Complete

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
  (including 56 root-solver assertions) after correcting lower-only expansion
  and total diagnostic evaluation accounting.
- Provenance: `validation/sources.toml` records every bracket, guardrail,
  tolerance, endpoint-stop, validation and evaluation-count policy with its
  implementation and regression invariant.
- Commits: `3ae4106` (`fix: harden scalar diagnostics and root expansion`);
  current provenance/status correction pending commit. This unit remains in
  progress while spec 005 is in progress.
