# Project charter

## Purpose

Define the scientific sources, implementation-independence rules, public scope, licensing and release criteria. This file is authoritative when later implementation choices conflict.

## Primary scientific source

The primary model source is:

- James C. Liljegren, Richard A. Carhart, Philip Lawday, Stephen Tschopp and Robert Sharp;
- “Modeling the Wet Bulb Globe Temperature Using Standard Meteorological Measurements”;
- *Journal of Occupational and Environmental Hygiene*, 5(10), 645–655, 2008;
- DOI: `10.1080/15459620802310770`.

Create `validation/sources.toml` and `docs/src/provenance.md`. Every equation, coefficient, physical constant and model policy must point to one of:

1. the primary paper;
2. a supporting publication cited by the paper;
3. an independently selected authoritative standard or publication;
4. an explicitly original numerical or API design decision.

Do not treat any software implementation as the scientific authority.

## Implementation-independence rule

`HeatStress.jl` must be newly written Julia source under MIT. It is not a code migration from HeatStressR or the original C implementation.

Permitted:

- derive equations and constants from publications;
- design a native Julia API, solver, data structures and threading strategy;
- reimplement general algorithmic ideas such as preallocation, grouped solar calculations, active-row processing or parallel execution from first principles;
- consult HeatStressR privately to remember the maintainer's prior optimisation intent;
- compare completed Julia outputs and performance against HeatStressR as a black box;
- record private comparison notes outside the distributed repository.

Not permitted in the MIT repository:

- copy or translate GPL-covered HeatStressR source;
- copy comments, documentation wording, tests, fixtures or distinctive code structure;
- use HeatStressR internal functions as fixture generators for ordinary CI;
- claim HeatStressR behaviour is normative when it conflicts with the paper or a documented scientific decision;
- copy the Argonne C source unless its licence and acknowledgement requirements are deliberately incorporated.

Prior authorship of optimisation work does not need to be resolved to ship v0.1.0: independently re-express the algorithms in Julia rather than copying exact source. Exact reuse is allowed only after confirming that the contributor personally owns the relevant copyright and has authority to relicense it under MIT.

Do not describe the project as “clean-room,” because the maintainer has prior familiarity with HeatStressR. Describe it as an **independent source implementation from published literature**.

## Private HeatStressR reference policy

HeatStressR may exist in a separate private workspace with no files copied into this repository. Add these patterns to `.gitignore`:

```gitignore
/dev/private/
/local-comparison/
```

A private comparison workflow may record:

- HeatStressR version and commit;
- input generation seed;
- output differences;
- benchmark timings;
- suspected discrepancies for investigation.

These results are advisory. Any discrepancy must be resolved against the literature, physical invariants, high-precision calculations or measured/published cases—not by automatically changing Julia to match R.

## Product scope

### Required for v0.1.0

1. Native Julia implementation of the outdoor Liljegren WBGT model.
2. Scalar globe-temperature and natural-wet-bulb calculations.
3. A documented solar-geometry implementation selected from cited literature.
4. Explicit structured diagnostics for invalid input and numerical failure.
5. Scalar, preallocated batch and threaded batch interfaces.
6. Independently sourced implementations of the selected secondary heat-stress indices.
7. Offline scientific fixtures derived from equations, published examples, high-precision calculations and invariants.
8. Cross-platform CI, documentation and benchmark harnesses.
9. No runtime or test dependency on R, RCall, HeatStressR, the original C executable or network access.

### Deferred beyond v0.1.0

- GPU kernels or CUDA/AMDGPU support.
- Distributed-memory execution.
- DataFrames-specific APIs.
- NetCDF, GRIB, CSV or weather-station file readers.
- Automatic interval alignment or wind-height adjustment.
- An R compatibility layer reproducing every HeatStressR argument name.
- Bitwise agreement with any prior software implementation.
- Unitful inputs, unless added as a package extension after core validation.
- A specialised lockstep vector root solver unless profiling demonstrates a clear benefit.

## Scientific conformance hierarchy

When requirements conflict, apply this order:

1. **Published model:** equations, units and physical assumptions.
2. **Explicit package contract:** documented choices where publications are incomplete or ambiguous.
3. **Physical and numerical invariants:** accepted roots, residual checks, monotonic relationships and dimensional consistency.
4. **Published or independently calculated cases:** values within declared tolerances.
5. **Cross-implementation comparison:** useful evidence, never sole authority.
6. **API familiarity:** optional assistance for users arriving from R.
7. **Implementation similarity:** not a goal.

## Required architectural rule

The implementation sequence must be:

1. transcribe each equation into a source-provenance table before coding;
2. implement and validate pure scalar physical kernels;
3. implement one canonical safeguarded scalar root solver;
4. compose the scalar Liljegren model;
5. add ordinary Julia batch loops and `!` APIs;
6. add threading and reusable solar preprocessing;
7. optimise only after profiling;
8. compare privately against HeatStressR only after the corresponding Julia path passes independent tests.

## Licensing and attribution

Release the package under the standard **MIT License**.

Add:

- `LICENSE`: standard MIT text with the package copyright holder and year;
- `CITATION.cff`: package citation and the primary scientific paper;
- `docs/src/provenance.md`: scientific sources, independent implementation statement, prior familiarity disclosure and implementation decisions;
- docstrings/source comments citing formula sources where useful;
- `CONTRIBUTING.md`: all contributions are submitted under MIT and must include lawful provenance.

A `NOTICE` file is optional under MIT. Use one only for scientific acknowledgements or third-party notices; do not imply extra licence conditions.

## Unit acceptance criteria

The project-charter unit is complete when:

- the primary source, conformance hierarchy, v0.1 scope and independence/licensing boundaries are explicitly approved;
- later specifications consistently refer to this charter where scientific or licensing authority matters;
- private-comparison paths and repository exclusions are defined;
- unresolved formula-level choices are delegated to their owning specifications rather than silently decided here.

Completion of this unit authorises downstream implementation. It does not claim that the product-level definition of done below has been met.

## Product definition of done

v0.1.0 is done only when:

- all exported APIs are documented;
- all tests pass on Linux, macOS and Windows;
- scientific fixtures and invariant tests pass;
- serial and threaded batch results have identical order, status and missingness and numerically equivalent values;
- scalar calls are type-stable and meet allocation targets;
- no R process or copied third-party implementation is used by package load, tests or fixture generation;
- provenance for every implemented formula family is recorded;
- the final scientific audit in spec 13 is complete.
