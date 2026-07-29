# v0.2 scientific audit: research

## Audit authorities

The added formula authorities and exact locators are recorded in
`validation/sources.toml`. Spec 000 remains the governing independence and
scientific-conformance hierarchy.

## Findings

- Added runtime code is confined to independently expressed Julia scalar
  formulas under `src/indices/`; no runtime/test dependency was added.
- Provenance scan found HeatStressR/Argonne references only in intentional
  independence and advisory-comparison documentation.
- Local full, four-thread, Aqua/JET, clean-depot, deterministic-fixture and
  warning-free documentation checks pass on Julia 1.10.11.
- Required Linux/Windows CI on the final PR head and its authorised squash
  merge form the external approval record. A new push reruns the gate; no
  follow-up audit commit is needed.
