# Final scientific audit and release authorisation

## Purpose

Run a strict final audit before publishing the Liljegren-first `v0.1.0` candidate. Audit one exact candidate source commit and only APIs, formulas and fixtures declared in the release scope. Secondary indices are audited when, and only when, a later release adds them.

## v0.1 release surface

The audit covers solar geometry and model-required psychrometric helpers; Liljegren globe, natural wet-bulb and WBGT calculations; scalar and diagnostic APIs; and serial, preallocated and threaded batch APIs. It does not require Stull, Bernard, humidex, heat index or other secondary-index provenance, fixtures or contracts.

## Source-provenance audit

Complete a table for every released function family:

| Function/component | Scientific source | Equation/section | Julia implementation | Tests | Status |
| --- | --- | --- | --- | --- | --- |
| solar geometry | | | | | |
| psychrometric helpers | | | | | |
| globe balance | Liljegren et al. 2008 | | | | |
| natural wet-bulb balance | Liljegren et al. 2008 | | | | |
| WBGT composition | | | | | |
| secondary indices (only in a future release) | | | | | out of v0.1 scope |

No released row may cite only HeatStressR or another software implementation.

## Liljegren contract audit

- [ ] input alignment and units;
- [ ] scalar/aligned coordinates, pressure and direct fraction;
- [ ] documented solar-time modes;
- [ ] negative wind/radiation and below-horizon policies;
- [ ] dewpoint policies and independently configurable tolerances;
- [ ] surface albedo, globe diameter and minimum wind;
- [ ] valid component retention and complete-WBGT missingness;
- [ ] unbracketed/non-finite/residual-invalid distinctions;
- [ ] scalar and diagnostic result types;
- [ ] serial, preallocated and threaded batch paths;
- [ ] row-aligned diagnostics and aggregate failure reporting;
- [ ] fixed/grouped/unique coordinate validation where supported.

## Independence audit

- [ ] no HeatStressR or Argonne source/translated material;
- [ ] no copied HeatStressR comments, docs, tests or fixture selection;
- [ ] no GPL-derived release file or incompatible dependency licence;
- [ ] released optimisation code is independently expressed;
- [ ] private comparator scripts/data are excluded by `.gitignore`;
- [ ] no runtime or CI dependency on R or another executable implementation;
- [ ] provenance discloses prior familiarity honestly.

Scan for `HeatStressR`, `GPL`, R dotted names, source hashes and private paths;
each remaining occurrence must be intentional documentation rather than
implementation provenance.

## Numerical validation report

Generate `validation/scientific-validation-report.md` for the released surface: audited package commit, fixture schema/version and counts, status/missingness mismatches, maximum/percentile output errors, largest differences, residual validation, serial/threaded comparison, Float32/Float64/BigFloat comparison, invariants and known deviations. Optional private cross-implementation findings are explicitly advisory.

Block release if any released fixture has undocumented status/missingness mismatch, an accepted root violates residual tolerance, threaded output differs in order/status from serial output, a released fixture lacks traceable source/generation method, or released source has unresolved licensing provenance.

## Quality audit

- [ ] clean-depot instantiate/test succeeds;
- [ ] Linux/macOS/Windows and threaded CI pass;
- [ ] Aqua passes and JET findings are reviewed;
- [ ] docs build without warnings;
- [ ] released hot-path allocations and benchmark metadata are reviewed;
- [ ] MIT licence/provenance, exports, `[compat]` and package-name conflict are reviewed;
- [ ] no uncommitted generated fixture edits remain.

## Final release decision

The validation report and decision record may be committed after the audited source commit. The record identifies the audited commit and permitted audit-record paths. Verify the resulting diff, then record the exact release commit in signed tag or release metadata.

```markdown
## v0.1.0 sign-off

- Release surface: `Liljegren-first v0.1.0 as declared in specs/README.md`
- Primary paper: `10.1080/15459620802310770`
- HeatStress.jl audited source commit: `<sha>`
- Permitted audit-record paths: `<paths>`
- Intended release ref: `verified audit-record commit`
- Validation report: `validation/scientific-validation-report.md`
- Implementation-independence audit: `<path/result>`
- Known deviations: `<list or none>`
- Approved by: `<name>`
- Date: `<UTC date>`
```

Approval authorises only listed audit records. If the candidate-to-release diff contains only those paths, tag that commit and then create the GitHub release, archival record and General registration submission. A released source, fixture or scientific-contract change after the audited source commit requires a new audit.

## Acceptance criteria

- every released source-provenance, contract, independence, numerical, quality and release-decision item has evidence;
- no release-blocking condition remains;
- the decision record identifies scope, audited source commit, permitted paths, validation report, approver, date and known deviations;
- the post-audit procedure verifies the diff and records the exact release commit before publication;
- no out-of-scope secondary index blocks v0.1.0.

## Suggested commit

`audit: authorise Liljegren-first v0.1.0 release candidate`
