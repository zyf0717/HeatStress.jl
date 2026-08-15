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
- Stable fixture paths plus Git history preserve evidence used for released
  versions while allowing the current scientific contract to be corrected.

## Known limits

- No field-observation dataset or implementation comparator is normative.
- Coverage percentage is diagnostic only.
- Test success does not prove the absence of all implementation errors.
- Spec 022 revision 2 intentionally contains bounded-Buck `Unbracketed` rows;
  these retain the globe component and leave WBGT missing. Float32 may
  additionally reject a located component at the residual threshold when its
  nearest representable candidate is insufficient.
