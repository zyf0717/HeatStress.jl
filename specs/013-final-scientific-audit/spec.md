# Final scientific audit

## Purpose

Run a final audit before declaring v0.1.0 complete. Verify scientific traceability, implementation independence, numerical correctness, API completeness and MIT-licence hygiene.

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

- package commit;
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

```markdown
## v0.1.0 sign-off

- Primary paper: `10.1080/15459620802310770`
- HeatStress.jl release commit: `<sha>`
- Validation report: `validation/scientific-validation-report.md`
- Implementation-independence audit: `<path/result>`
- Known deviations: `<list or none>`
- Approved by: `<name>`
- Date: `<UTC date>`
```

## Suggested commit

`release: complete HeatStress.jl v0.1.0 scientific audit`

---

# Implementation PR sequence

Use small, reviewable PRs. The implementation agent should not attempt the entire package in one branch.

| PR | Specs | Required result |
| ---: | --- | --- |
| 1 | 00–01 | scaffold, CI, policy documents |
| 2 | 02–03 | API/types/constants/validation |
| 3 | 04 | solar geometry and psychrometrics |
| 4 | 05 | pure physical kernels |
| 5 | 06 | root solver and diagnostics |
| 6 | 07 | scalar Liljegren model |
| 7 | 08 | batch, preallocation and threading |
| 8 | 09 | remaining indices |
| 9 | 10 | paper-derived fixtures and scientific validation suite |
| 10 | 11 | profiling, optimisation and quality gates |
| 11 | 12–13 | MIT documentation, scientific audit and v0.1.0 release |

Each PR must:

1. state which spec acceptance criteria it closes;
2. include tests with the implementation;
3. avoid unrelated refactors;
4. update checkboxes/evidence in specs;
5. report commands actually run;
6. keep future APIs unexported until complete.

# Instructions for a weaker implementation model

Follow these rules literally:

1. Read the current spec and all prerequisite specs before modifying code.
2. Read the cited paper section and provenance record before implementing any formula.
3. Do not inspect HeatStressR source while writing the corresponding Julia function.
4. Implement the smallest scalar function first.
5. Add direct unit, dimensional and high-precision tests before composition.
6. Use explicit types and descriptive names; do not build abstraction layers without a current use.
7. Never replace a signed root with minimisation of `abs(residual)` unless the spec explicitly permits it.
8. Never accept a root merely because the solver stopped; validate the final residual separately.
9. Never turn failed values into zero, clamp them arbitrarily or drop failed rows.
10. Preserve input order and valid component outputs.
11. Run the narrow test file after each change, then full `Pkg.test()` before commit.
12. When validation fails, print the exact input, Julia result, expected result, source ID, status, residual and bracket. Diagnose before increasing tolerance.
13. Do not optimise before scalar scientific validation.
14. Optimisation ideas remembered from prior HeatStressR work must be re-expressed from first principles in new Julia code; do not copy source.
15. Do not add dependencies to replace a few clear tested functions.
16. Do not claim a spec complete without evidence paths and passing commands.
17. Stop and document ambiguity in the literature rather than silently inventing scientific behaviour.

# Recommended AGENTS.md summary

The repository may include this concise implementation instruction:

```markdown
# AGENTS.md

Implement work in `specs/` order. HeatStress.jl is a new MIT-licensed Julia
implementation derived from the Liljegren paper and independently cited
supporting literature; it is not a migration from HeatStressR. Record a source
for every equation, constant and policy before coding. Build scalar type-stable
kernels and one safeguarded root solver first, then ordinary loops,
preallocation, solar reuse and Julia threads. Do not copy HeatStressR or the
Argonne C source, comments, tests, fixtures or implementation structure.
HeatStressR may be used only in a separate private workspace as an advisory
black-box comparison after independent tests pass. Preserve units, physical
assumptions, valid component outputs and explicit failure semantics. Update
spec checkboxes with test and commit evidence.
```

# Source references

- Primary paper: Liljegren JC, Carhart RA, Lawday P, Tschopp S, Sharp R. “Modeling the Wet Bulb Globe Temperature Using Standard Meteorological Measurements.” *Journal of Occupational and Environmental Hygiene*. 2008;5(10):645–655. DOI: <https://doi.org/10.1080/15459620802310770>
- Julia package creation and naming guidance: <https://pkgdocs.julialang.org/v1/creating-packages/>
- Julia style guide: <https://docs.julialang.org/en/v1/manual/style-guide/>
- Julia project metadata: <https://pkgdocs.julialang.org/v1/toml-files/>
- MIT License text: <https://opensource.org/license/mit/>

## Private comparator note

HeatStressR is intentionally absent from the public source-reference list because it is not an implementation source for the MIT package. The maintainer may retain a private comparison checkout and notes outside the repository. Public documentation may mention HeatStressR only to disclose prior familiarity, describe non-normative interoperability or report a reproducible black-box benchmark without copying GPL material.

