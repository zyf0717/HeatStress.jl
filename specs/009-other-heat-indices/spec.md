# Secondary heat measures

## Purpose

Add a focused v0.2.0 set of independently sourced scalar heat measures without
changing the released Liljegren APIs. HeatStressR may inform private feature
prioritisation, but it is not a formula or validation source.

## Selected v0.2 formulas

| Public name | Selected authority and formulation | Inputs | Output/applicability |
| --- | --- | --- | --- |
| `wbgt_with_solar_load` | OSHA measured-component WBGT: `0.7Tnwb + 0.2Tg + 0.1Tdb` | natural wet-bulb, globe and dry-bulb temperatures in °C | WBGT in °C; solar/radiant-load environments |
| `wbgt_without_solar_load` | OSHA measured-component WBGT: `0.7Tnwb + 0.3Tg` | natural wet-bulb and globe temperatures in °C | WBGT in °C; indoors or outdoors without solar load |
| `heat_index_nws` | Current NWS operational procedure: simple Steadman-consistent estimate, Rothfusz regression and low/high-RH adjustments | air temperature in °C and RH in percent | heat index in °C; shaded, resting-person interpretation |
| `wet_bulb_temperature_stull` | Stull (2011), equation 1 | air temperature in °C and RH in percent | wet-bulb approximation in °C at 101.325 kPa; `T ∈ [-20, 50]`, `RH ∈ [5, 99]` |
| `humidex` | Environment and Climate Change Canada standard dew-point formulation | air temperature and dew point in °C | dimensionless humidex value customarily expressed on a Celsius-like scale |

The Stull paper qualitatively excludes combinations having both low humidity
and cold temperature but gives no algebraic boundary for that region. Enforce
the published numeric rectangle and document the qualitative exclusion rather
than inventing a threshold.

The NWS operational procedure gives no exact outer air-temperature limits for
the complete piecewise algorithm. Enforce finite temperature and RH in
`[0, 100]`, implement the published branch procedure exactly, and document the
NWS warning that the regression is not valid for extreme conditions.

ECCC's rule for displaying humidex only above specified reporting thresholds is
a presentation policy, not part of the formula domain. `humidex` evaluates the
formula for finite physically consistent inputs with dew point above absolute
zero and no greater than air temperature.

## API and numerical contract

Each measure is a pure scalar function. Array behavior uses ordinary Julia
broadcasting. Do not add aligned-array, batch-result or diagnostic containers
for these direct formulas.

- Promote real inputs to a floating type and preserve Float32 when all real
  inputs are Float32.
- Return `missing` when any input is `missing`.
- Throw `DomainError` for non-finite or out-of-domain real inputs.
- Keep formula coefficients in the promoted type.
- Do not silently clamp, extrapolate past numeric bounds, or convert RH
  fractions to percentages.
- Cite the exact authority, formulation, units and limitations in every public
  docstring.

## Source and independence requirements

Before implementing a formula, add its authority and equation/policy entries to
`validation/sources.toml` with `status = "specified"`. Advance entries to
`implemented` and `validated` only when the referenced source and validation
paths exist.

Transcribe equations from the selected publications or government technical
pages. Do not copy or translate HeatStressR, another package, or third-party
test fixtures.

## Validation

For every selected formula:

- independently calculate direct or 256-bit expected values without importing
  `HeatStress`;
- test each formula/branch boundary and invalid-domain boundary;
- verify scalar/broadcast equivalence, Float32/Float64 behavior, promotion and
  missing propagation;
- store traceable rows in `validation/fixtures/simple_indices.csv`;
- report the worst mismatching row and source identifier.

Heat-index tests cover the simple/full transition, both humidity adjustments
and every documented temperature/RH threshold immediately below, at and above
the boundary.

## Deferred candidates

Bernard WBGT, empirical simplified WBGT, apparent temperature, effective
temperature, discomfort index and UTCI are not selected for v0.2.0 and do not
block this unit. Each requires a later release scope and exact formulation;
UTCI additionally requires mean-radiant-temperature and 10 m wind contracts.

`relative_humidity_from_dewpoint` and `vapour_pressure` remain psychrometric
functions owned by spec 004.

## Acceptance criteria

- all five exports implement the selected authoritative formulations;
- public names expose formulation or physical-load semantics;
- domain and missing behavior matches this specification;
- scientific fixtures and formula-specific tests pass;
- documentation distinguishes measured-component WBGT, modeled Liljegren WBGT,
  heat index, wet-bulb approximation and humidex;
- no R aliases, generic heat-index aliases or unselected measures are exported.

## Suggested commit

`feat: add independently sourced secondary heat measures`
