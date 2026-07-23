# Solar geometry and psychrometrics

## Purpose

Implement reusable solar and humidity calculations as pure, independently sourced Julia functions before the Liljegren model.

## Source-selection gate

Before coding, add a table to this spec:

| Component | Selected publication/standard | Equation/section | Units | Notes |
| --- | --- | --- | --- | --- |
| solar zenith | | | | |
| saturation vapour pressure | | | | |
| RH from dewpoint | | | | |
| atmospheric emissivity | | | | |
| air viscosity | | | | |
| diffusivity | | | | |

The implementation agent must not take coefficients from HeatStressR, the original C source or memory. If the Liljegren paper delegates a subformula to another reference, obtain and cite that reference or select an independently justified authoritative formulation and document the resulting model difference.

## Solar geometry

Select a documented solar-position approximation suitable for hourly meteorological calculations. Requirements:

- accepts a UTC instant, longitude and latitude;
- handles leap years and day-of-year correctly;
- provides solar zenith in a stated angular unit;
- is continuous and stable near sunrise/sunset;
- clamps inverse-trigonometric inputs against floating-point drift;
- has a documented expected error appropriate for WBGT calculations;
- can be decomposed into time-only and coordinate-dependent terms for batch reuse.

Do not hard-code a coefficient set until its publication and equation are recorded. Do not copy `calZenith.R` or use its operation order as the specification.

## Solar-time modes

### `TimestampSolarTime`

Use the full instant. Convert `ZonedDateTime` to UTC. Equivalent instants with different offsets must produce identical zenith.

### `DateNoonSolarTime`

Use the UTC calendar date at 12:00 UTC. Retain this mode only if it serves a documented scientific or compatibility use case; otherwise defer it from v0.1.0.

Use explicit policy values, not paired Boolean switches.

## Scalar API

```julia
solar_zenith(time, longitude_deg, latitude_deg; mode=TimestampSolarTime)
```

Return degrees publicly unless the package charter is amended. Add internal helpers only after the selected equations are known:

```julia
_solar_zenith_radians(...)
_solar_time_terms(...)
_zenith_from_terms(...)
```

## Batch optimisation

After scalar scientific validation:

- accept aligned time/longitude/latitude arrays;
- permit scalar coordinate expansion;
- calculate time-only terms once per unique instant where profitable;
- group repeated coordinate pairs using typed keys or index maps;
- preserve input order;
- avoid string construction in hot paths;
- benchmark fixed, grouped and unique-coordinate workloads separately.

## Psychrometric functions

Implement, where required by the selected source set:

```julia
relative_humidity_from_dewpoint(air_temperature_c, dew_point_c)
vapour_pressure(air_temperature_c, relative_humidity_percent)
saturation_vapour_pressure_hpa(...)
emissivity_atmosphere(air_temperature_k, vapour_pressure_or_rh)
viscosity_air(temperature_k)
diffusivity_coefficient(pressure_hpa)
diffusivity_air(temperature_k, pressure_hpa)
```

Names must encode units or clearly document them. Do not combine RH percent and fraction in ambiguously named functions.

## Formula transcription procedure

For each helper:

1. copy the equation into the spec using mathematical notation, not source code;
2. list every symbol and unit;
3. record constants and conversion factors;
4. derive at least one hand-checkable or BigFloat case;
5. implement the scalar Julia function from the equation;
6. compare the implementation to the independently calculated case;
7. only then compose it into higher-level kernels.

## Tests

### Solar tests

- equinox and solstice cases;
- leap/non-leap years;
- midnight/noon;
- longitudes near ±180°;
- high latitudes and polar-adjacent values;
- equivalent instants under several UTC offsets;
- horizon crossings;
- scalar versus batch equality;
- grouped versus row-by-row equality;
- empty and one-row arrays;
- comparison against published examples or an independent high-accuracy solar library used only in validation.

### Psychrometric tests

- saturation identity: dewpoint equals air temperature gives approximately 100% RH;
- lower dewpoint gives RH below 100%;
- monotonicity across selected domains;
- analytic or BigFloat cases;
- scalar versus broadcast equality;
- Float32 and Float64;
- finite results across the documented domain;
- explicit out-of-domain behaviour.

## Acceptance criteria

- every coefficient is traceable to a publication or explicit original policy;
- solar zenith meets the accuracy tolerance declared for the selected method;
- same-instant zoned timestamps are equal;
- no string parsing occurs in scalar numeric kernels;
- batch output is order-preserving;
- public unit names/docstrings are unambiguous;
- no source-code implementation is cited as the sole formula authority.

## Suggested commit

`feat: implement sourced solar geometry and psychrometrics`

