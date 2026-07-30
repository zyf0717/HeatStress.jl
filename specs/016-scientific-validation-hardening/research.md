# Scientific validation hardening: research

## Assurance boundary

This unit establishes implementation conformance to the package's selected
published equations. It does not establish empirical robustness. Standalone
high-precision calculation reduces shared numerical-method risk but cannot
alone exclude a transcription error shared with production code.

## Risk controls

- Published examples, analytic identities and external solar references remain
  distinct authorities from standalone equation evaluation.
- Pairwise factor coverage exposes interaction defects without claiming
  exhaustive input-space proof.
- Synthetic solver fixtures exercise failure machinery that is unsafe or
  impossible to induce through valid meteorological observations.
- Frozen historical fixture sets preserve the evidence used for released
  versions.

## Known limits

- No field-observation dataset or implementation comparator is normative.
- Coverage percentage is diagnostic only.
- Test success does not prove the absence of all implementation errors.
- Seven v3 reference rows exceed the `1e-4 K` component residual threshold in
  Float32 because the nearest representable candidate produces a residual of
  approximately `1.07e-4` to `2.75e-4 K`. Their affected component and complete
  WBGT remain missing as required; the other component is retained. Float64
  accepts all 64 rows.
