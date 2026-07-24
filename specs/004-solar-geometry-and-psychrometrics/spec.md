# Solar geometry and psychrometrics

## Purpose

Implement reusable solar and humidity calculations as pure, independently sourced Julia functions before the Liljegren model.

## Source-selection gate

| Component | Selected publication/standard | Equation/section | Units | Notes |
| --- | --- | --- | --- | --- |
| solar zenith | Spencer (1971) | equations 1–4, *Search* 2:172 | radians, degrees | third-harmonic declination and second-harmonic equation of time; expected error ≤2° in zenith at hourly resolution; suitable for WBGT solar forcing |
| saturation vapour pressure | Allen et al. (1998), FAO-56 | equation 11, *Crop Evapotranspiration* | hPa | Magnus-Tetens form; T in °C; standard agricultural/hydrology reference |
| RH from dewpoint | derived from saturation VP | e(T_d) / e_s(T_a) | fraction | Compute e_s at dewpoint and air temperature via Magnus-Tetens; RH = 100 × e(T_d) / e_s(T_a) |

Accuracy target: solar zenith error ≤ 2° vs. high-accuracy ephemeris at hourly resolution (Liljegren WBGT solar forcing is insensitive to sub-degree precision).

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

Use the full instant. Convert `ZonedDateTime` to UTC. Equivalent instants with different offsets must produce identical zenith. `DateNoonSolarTime` has no documented scientific or compatibility use case, so it is not part of the v0.1 public contract; `Date` inputs are rejected by dispatch.

## Scalar API

```julia
solar_zenith(time, longitude_deg, latitude_deg)
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
```

Names must encode units or clearly document them. Do not combine RH percent and fraction in ambiguously named functions.

Atmospheric emissivity, viscosity and diffusivity belong to the heat-transfer layer in spec 005, even when they consume psychrometric outputs. This unit owns only solar geometry and public humidity/vapour-pressure calculations.

## Formula transcription procedure

For the solar calculation, with `n` the UTC day of year (unitless), `t` the
UTC minute of day (min), `λ` longitude (degrees, positive east), and `φ`
latitude (radians), Spencer's equations are:

\[
\gamma = 2\pi(n - 1)/365
\]
\[
\delta = 0.006918 - 0.399912\cos\gamma + 0.070257\sin\gamma
- 0.006758\cos2\gamma + 0.000907\sin2\gamma
- 0.002697\cos3\gamma + 0.00148\sin3\gamma
\]
\[
E = (720/\pi)[0.000075 + 0.001868\cos\gamma - 0.032077\sin\gamma
- 0.014615\cos2\gamma - 0.040849\sin2\gamma]\quad\mathrm{min}
\]
\[
H = \pi[t + E + 4\lambda - 720]/720,\qquad
z = \arccos(\sin\phi\sin\delta + \cos\phi\cos\delta\cos H).
\]

The factor `4 min/degree` converts east-positive longitude to local mean
solar time. `acos` receives its argument clamped to [-1, 1]. `γ`, `δ`, `H`,
and `z` are radians internally; `z` is converted to degrees at the public
boundary. The source's 365-day approximation is intentionally retained on
leap-year day 366.

For psychrometrics, FAO-56 equation 11 is:

\[
e_s(T) = 6.108\exp[17.27T/(T+237.3)]\quad\mathrm{hPa},
\]

where `T` is degrees Celsius. Actual vapour pressure is
`e = RH_percent e_s(T) / 100`, and humidity from dew point is
`RH_percent = 100 e_s(T_d) / e_s(T_a)`. The explicit valid temperature domain
is -40 to 50 °C; non-finite and out-of-domain temperatures, and RH outside
0--100 percent for `vapour_pressure`, throw `ArgumentError`.

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
