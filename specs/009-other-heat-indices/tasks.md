# Secondary heat measures: execution checklist

## Status

- [ ] Planned
- [ ] In progress
- [x] Complete

## Tasks

- [x] Select the v0.2 formulas, public names, native inputs and domain policy.
- [x] Record every selected formula and policy in the provenance registry.
- [x] Implement and export the five selected scalar APIs.
- [x] Add formula, branch, domain, type, broadcast and missing tests.
- [x] Validate independent simple-index fixtures through spec 010.
- [x] Document sources, units, applicability and limitations.
- [x] Run the acceptance checks in `quickstart.md`.
- [x] Record validation evidence and candidate commit handoff below.

## Evidence

- Evidence: `test/test_secondary_indices.jl` passes 85 assertions covering
  equations, NWS branches/boundaries, domains, Float32/Float64, promotion,
  broadcasting and missing propagation. The full and four-thread suites,
  Aqua/JET quality suite, clean-depot suite, deterministic fixture check and
  warning-free documentation build pass locally on Julia 1.10.11.
- Scientific fixtures: `validation/fixtures/simple_indices.csv`, independently
  regenerated at 256-bit precision by
  `validation/generate_simple_indices.jl`; the scientific-validation corpus
  passes 316 assertions.
- Commit: exact candidate source commit is recorded by spec 015 after freeze.
