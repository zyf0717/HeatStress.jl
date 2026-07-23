# Liljegren scalar model

## Purpose

Compose policies, solar geometry, psychrometrics, kernels and the root solver into the canonical scalar Liljegren implementation.

## Implementation sequence

### Step 1: preprocess one observation

Create an internal function that returns either:

- a concrete prepared observation containing Kelvin temperatures, RH, zenith, adjusted radiation, pressure, direct fraction, adjustment flags and solar-mismatch state; or
- an input-status failure.

Do not invoke either component solver until preprocessing reports `InputAccepted`.

### Step 2: prepare globe balance

Using the equations documented from the primary paper and supporting sources:

1. convert air temperature to Kelvin;
2. convert RH percent to fraction;
3. apply the sourced, shared solar-forcing/horizon policy defined by specs 004–005;
4. calculate effective wind;
5. calculate atmospheric/surface longwave term;
6. calculate direct/diffuse solar term using `direct_fraction`, surface albedo, globe albedo, emissivity and Stefan-Boltzmann constant;
7. build `GlobeBalance`;
8. solve using globe bracket policy;
9. validate with Kelvin-scale globe residual;
10. convert accepted root to Celsius.

### Step 3: prepare natural wet-bulb balance

1. convert air/dewpoint to Kelvin;
2. calculate RH fraction and vapour pressure;
3. calculate atmospheric emissivity;
4. calculate air density, viscosity and diffusivity coefficient;
5. calculate effective wind, longwave and solar terms;
6. build `WetBulbBalance`;
7. solve using wet-bulb bracket policy;
8. validate signed residual;
9. convert accepted root to Celsius.

### Step 4: calculate WBGT

Only when both component values are accepted:

```text
WBGT = 0.7 × natural_wet_bulb +
       0.2 × globe_temperature +
       0.1 × air_temperature
```

Retain an independently valid component when the other component fails.

## Public functions

### `globe_temperature`

Value-only public scalar function. Return `Union{Missing,T}`.

### `natural_wet_bulb_temperature`

Value-only public scalar function. Return `Union{Missing,T}`.

### `liljegren_wbgt`

Return `WBGTResult`.

### `diagnose_liljegren`

Return `DiagnosticWBGTResult` with both component diagnostics, input status, input-adjustment flags and solar mismatch flag.

Value-only functions should call the same internal diagnostic computation and discard diagnostics only if profiling shows no avoidable overhead. Do not maintain two scientifically divergent solver implementations.

## Direct fraction

- scalar finite value from 0 through 1;
- interpreted as `direct / (direct + diffuse)`;
- default `0.8` only if supported by the selected model/instrument source, with citation;
- not inferred from global radiation;
- validate before solver invocation.

## Pressure

- scalar pressure in hPa;
- default 1010 hPa;
- positive and finite;
- no elevation conversion in v0.1.

## Solar forcing semantics

- solar zenith uses timestamp/coordinates and equation of time;
- supplied radiation is not interval-normalised;
- negative radiation becomes zero;
- solar forcing is zero when computed solar elevation is not positive;
- mismatch flag does not by itself invalidate the row.

## Tests

Create small explicit fixtures:

1. ordinary daytime case;
2. night-time case with radiation supplied;
3. zero-wind case;
4. high-radiation/near-horizon case;
5. saturated air;
6. dewpoint above air under each policy;
7. missing time;
8. missing meteorology;
9. invalid pressure/direct fraction/config;
10. known failed globe component;
11. known failed natural wet-bulb component if available;
12. same instant represented in different time zones;
13. Float32 ordinary case;
14. published and independently constructed validation cases.

For each ordinary case assert:

- component values are finite;
- WBGT formula reconstructs exactly from returned components and input air temperature within floating error;
- accepted residuals pass tolerance;
- result and diagnostic result values are identical.

## Numerical validation tolerances

Initial scientific fixture comparisons:

- component and WBGT: `atol=1e-4 °C`, `rtol=1e-8`;
- accepted residual: configured tolerance;
- missingness and input status: exact;
- failure reason: exact where bracket policy and source arithmetic make it meaningful.

If Julia bisection produces systematically different but valid roots within the root tolerance, retain scientific tolerance rather than forcing identical iteration history.

## Allocation and inference targets

After compilation, for a Float64 scalar value-only call with `DateTime`:

- type inference must succeed;
- target zero heap allocations, excluding unavoidable timezone conversion paths;
- diagnostic call may allocate a small fixed amount initially but should remain independent of input history.

Do not compromise correctness to hit zero allocation before scientific validation passes.

## Acceptance criteria

- scalar scientific fixture passes;
- diagnostic and value-only calls agree;
- all component failures preserve valid counterpart values;
- complete WBGT never exists when either component is missing;
- no R code or R-shaped vector logic exists in the scalar path.

## Suggested commit

`feat: implement scalar Liljegren WBGT model`
