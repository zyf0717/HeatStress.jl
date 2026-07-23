# Final scientific audit and release authorisation

## Purpose

Run a final audit before declaring v0.1.0 complete or taking any publication action. Verify scientific traceability, implementation independence, numerical correctness, API completeness and MIT-licence hygiene for one exact candidate source commit.

## Source-provenance audit

Complete a table for every implemented function family:

| Function/component | Scientific source | Equation/section | Julia implementation | Tests | Status |
| --- | --- | --- | --- | --- | --- |
| solar geometry | | | | | |
| psychrometrics | | | | | |
| globe balance | Liljegren et al. 2008 | | | | |
| natural wet-bulb balance | Liljegren et al. 2008 | | | | |
| WBGT composition | | | | | |
| secondary indices | | | | | |

No row may cite only HeatStressR or another software implementation.

## Liljegren contract audit

Verify one by one:

- [ ] input alignment and units;
- [ ] scalar/aligned coordinates, pressure and direct fraction;
- [ ] documented solar-time modes;
- [ ] negative wind/radiation policy;
- [ ] below-horizon treatment;
- [ ] dewpoint policies;
- [ ] independently configurable root/residual/dewpoint tolerances;
- [ ] surface albedo, globe diameter and minimum wind;
- [ ] valid component retention;
- [ ] complete-WBGT missingness;
- [ ] unbracketed/non-finite/residual-invalid distinctions;
- [ ] scalar and diagnostic result types;
- [ ] serial, preallocated and threaded batch paths;
- [ ] row-aligned diagnostics and aggregate failure reporting;
- [ ] fixed/grouped/unique coordinate validation.

## Independence audit

Confirm:

- [ ] no HeatStressR source or translated code;
- [ ] no copied HeatStressR comments, docs, tests or fixture selection;
- [ ] no copied Argonne C source or required notices omitted;
- [ ] no GPL-derived file in the repository history intended for release;
- [ ] optimisation code is newly expressed in Julia from general algorithmic ideas;
- [ ] private comparator scripts/data are excluded by `.gitignore`;
- [ ] no runtime or CI dependency on R or another executable implementation;
- [ ] provenance discloses prior familiarity honestly;
- [ ] every dependency licence is compatible with MIT distribution.

Run a repository scan for `HeatStressR`, `GPL`, copied R dotted names, source commit hashes and private paths. Every remaining occurrence must be intentional documentation, not implementation provenance.

## Numerical validation report

Generate `validation/scientific-validation-report.md` containing:

- audited package commit;
- fixture schema/version and counts by authority level;
- exact status/missingness mismatch count;
- maximum and percentile errors by output;
- rows with largest differences;
- residual-validation summary;
- serial versus threaded comparison;
- Float32/Float64/BigFloat comparison;
- invariant-test summary;
- optional private cross-implementation findings, clearly marked advisory;
- known and accepted deviations.

Block release if:

- any expected status/missingness mismatch is undocumented;
- any accepted root violates configured residual tolerance;
- any direct-formula index exceeds its declared tolerance;
- threaded output differs in order/status from serial output;
- a fixture lacks a traceable source or generation method;
- any released source has unresolved licensing provenance.

## Quality audit

- [ ] clean-depot instantiate/test succeeds;
- [ ] Linux/macOS/Windows CI passes;
- [ ] threaded CI passes;
- [ ] Aqua passes;
- [ ] JET findings reviewed;
- [ ] docs build without warnings;
- [ ] allocation targets measured;
- [ ] benchmark metadata recorded;
- [ ] MIT licence/provenance reviewed;
- [ ] package-name conflict rechecked;
- [ ] no uncommitted generated fixture edits.

## Final release decision

The validation report and completed decision record may be committed after the audited source commit. A commit cannot contain its own hash, so the in-repository decision identifies the audited source commit and the permitted audit-record paths. After committing those records, verify the resulting diff and record the exact release commit in the signed tag or release metadata.

```markdown
## v0.1.0 sign-off

- Primary paper: `10.1080/15459620802310770`
- HeatStress.jl audited source commit: `<sha>`
- Permitted audit-record paths: `<paths>`
- Intended release ref: `the verified audit-record commit; record its SHA in the signed tag/release metadata`
- Validation report: `validation/scientific-validation-report.md`
- Implementation-independence audit: `<path/result>`
- Known deviations: `<list or none>`
- Approved by: `<name>`
- Date: `<UTC date>`
```

Approval authorises committing the listed audit records. If the resulting candidate-to-release diff contains only those paths, tag that commit and then create the GitHub release, archival record and General registration submission. Any source, fixture or scientific-contract change after the audited source commit invalidates the authorisation and requires a new audit.

## Acceptance criteria

- every source-provenance, independence, numerical, quality and release-decision item above has evidence;
- no release-blocking condition remains;
- the decision record identifies the audited source commit, permitted audit-record paths, validation report, approver, date and known deviations;
- the post-audit procedure requires diff verification and recording the exact audit-record release commit in signed tag or release metadata before publication.

## Suggested commit

`audit: authorise HeatStress.jl v0.1.0 release candidate`
