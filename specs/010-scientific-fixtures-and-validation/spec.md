# Scientific fixtures and validation

## Purpose

Create reproducible offline validation that is independent of HeatStressR and
any other executable implementation. Validation is release-scoped: v0.1.0
requires evidence for the Liljegren/core surface only, while future APIs add
their own fixture requirements when introduced.

## Validation sources

Create:

```text
validation/
├── README.md
├── sources.toml
├── generate_validation_cases.jl
├── high_precision/
│   ├── Project.toml
│   └── recompute_cases.jl
├── metadata/
│   └── fixture-set-v1.toml
└── fixtures/
    ├── solar_geometry.csv
    ├── psychrometrics.csv
    ├── physical_kernels.csv
    ├── liljegren_components.csv
    ├── liljegren_reference.csv
    ├── liljegren_failures.csv
    └── simple_indices.csv
```

`sources.toml` must map every fixture family to publications, standards, equations and generation method. `fixture-set-v1.toml` must record the fixture-generator revision, Julia version, precision, timezone, random seed and schema version. A validation report records the package commit being tested; regenerating fixtures must not rewrite metadata merely because unrelated package code changed.

## Fixture authority levels

Label every expected result as one of:

1. `published_example` — value printed in a paper or authoritative source;
2. `analytic` — closed-form or identity-derived value;
3. `high_precision` — recomputed with BigFloat and tighter solver tolerances;
4. `invariant` — expected relationship/status rather than a fixed decimal;
5. `measured_comparison` — published measurement/model comparison;
6. `cross_implementation_advisory` — optional private comparison, not committed as normative truth.

The package test suite must not depend solely on level 6.

## Required fixtures

### `solar_geometry.csv`

Cover leap/non-leap dates, multiple UTC hours, equivalent zoned instants, equatorial/mid/high latitudes, longitudes near ±180°, horizon crossings, polar-adjacent cases and whichever explicit solar-time modes the package supports.

### `psychrometrics.csv`

Cover air temperature approximately `-30` to `60 °C`, dry through saturated conditions, RH boundaries and representative pressure/elevation values. Include analytic saturation identities.

### `physical_kernels.csv`

Store independently calculated viscosity, diffusivity, convection/radiation terms and residual evaluations. Generate with high precision from the documented equations, not by invoking private functions in another package.

### `liljegren_components.csv`

Store successful Tg and Tnwb roots, Kelvin-scale validation residuals, brackets and expected status. Expected roots should be generated with BigFloat and a solver tighter than the production defaults.

### `liljegren_reference.csv`

Include:

- a small human-reviewable set;
- day/night cases;
- pressure and direct-radiation variation;
- fixed, grouped and unique coordinates;
- dewpoint-policy cases;
- horizon and high-radiation cases;
- rows reconstructed from published examples or figures where numerically possible.

Columns include all inputs, WBGT, Tg, Tnwb, authority level, source identifier, status and tolerance.

### `liljegren_failures.csv`

Construct and document invalid-input, unbracketed, non-finite and residual-rejection cases. Do not remove failed rows from fixtures.

### `simple_indices.csv` (v0.2)

Cover the spec 009 measured WBGT equations, NWS heat-index branch families,
Stull wet-bulb approximation and ECCC humidex. Store formula identifiers,
normalized nullable inputs, expected values, authority levels, source
identifiers and per-row tolerances. Generate expected values independently
without importing `HeatStress`.

## Release-scoped validation

### Required before v0.1.0

The v0.1 validation slice covers every released formula and API:

- independent Liljegren scalar/component fixtures and provenance;
- scalar, allocating batch, preallocated batch and threaded equivalence;
- exact status, missingness, input-policy and diagnostic checks;
- residual-tolerance verification and component-retention behaviour;
- Float32/Float64 coverage, with BigFloat comparisons where the fixture
  authority uses high precision;
- fixed, grouped and unique-coordinate validation where the batch contract
  supports those modes;
- source records for solar geometry, psychrometrics, physical kernels and all
  released Liljegren formula families.

Independent Liljegren fixtures and regression tests are stable by path, not
immutable by content. A later sourced scientific correction may replace them
in place when its generator, provenance, sensitivity and audit evidence are
updated together; Git history preserves the released values. Spec 022 is the
first such authorized replacement.

### v0.2 validation slice

- independent selected-formula fixtures and provenance;
- exact NWS branch and adjustment boundaries in direct tests;
- scalar/broadcast equivalence, missing propagation and Float32/Float64;
- formula-specific domain rejection and tolerances;
- worst-row and source-identifier mismatch reporting.

### Deferred beyond v0.2.0

- validation for future formula variants or APIs not in the selected release
  scope, including UTCI;
- any fixture family whose formula-selection gate remains unresolved.

Do not require validation for unimplemented or unreleased APIs before General
registration.

## Independent validation tests

`test/test_scientific_validation.jl` must:

1. load fixture CSVs;
2. parse explicit missing values and authority metadata;
3. call scalar or batch APIs;
4. compare status/missingness exactly;
5. compare finite values with per-row or per-function tolerances;
6. print the worst row and all inputs on failure;
7. verify that production roots satisfy configured residual checks;
8. avoid one global tolerance.

Suggested starting tolerances:

| Quantity | Tolerance |
| --- | --- |
| direct algebraic formula | `atol=1e-10`, `rtol=1e-10` for Float64 |
| solar zenith transcription/numerics | source/method-specific; compare against a higher-precision evaluation of the same selected method |
| solar-method accuracy | the error bound declared in spec 004 against an independent higher-accuracy authority |
| heat-transfer kernels | `atol=1e-10`, `rtol=1e-10` where numerically suitable |
| Liljegren Tg/Tnwb/WBGT | `atol=1e-4 °C`, `rtol=1e-8` |
| accepted residual | configured residual tolerance |

Adjust only after inspecting error sources and documenting the rationale.

## Invariant suite

At minimum verify:

- RH is approximately 100% when dewpoint equals air temperature;
- accepted roots satisfy residual criteria;
- WBGT recomposes exactly from accepted components within floating-point tolerance;
- night-time direct solar forcing is zero under the selected solar policy;
- row order does not alter values;
- serial/threaded results agree;
- pressure and direct fraction reach the intended physical terms;
- no complete WBGT is returned when a required component fails;
- tighter solver tolerances do not materially change accepted production values;
- Float64 results converge toward BigFloat reference values.

## Optional private cross-implementation comparison

Outside the repository, compare against HeatStressR and, where useful, the Argonne implementation. Record only summary findings in maintainer notes unless the comparison data can be lawfully and independently regenerated.

A disagreement must be classified as:

- source-formula difference;
- policy difference;
- numerical-method difference;
- likely Julia defect;
- likely comparator defect;
- unresolved.

Do not change Julia merely to reduce the numeric difference.

## Regeneration policy

Fixture changes require:

- source/equation or generator change;
- metadata update;
- a maximum-difference summary;
- maintainer review;
- no manual editing of generated numerical columns.

## Acceptance criteria

- ordinary tests require only Julia;
- fixture generation is deterministic;
- expected values are traceable to literature, analytic identities or high-precision calculation;
- fixtures include failures and domain boundaries;
- every function in the declared release surface has independent scientific
  coverage, including the selected v0.2 secondary measures;
- CI failures identify the worst row and source identifier.

## Suggested commit

`test: add paper-derived scientific validation fixtures`
