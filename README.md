# HeatStress.jl

HeatStress.jl is an independent MIT-licensed Julia package for heat-stress
measures. It implements the Liljegren outdoor wet-bulb globe temperature
(WBGT) model, RCCD167L and the RCC-documented NWS estimated-WBGT combination,
measured-component WBGT, the US National Weather Service heat
index, the Stull wet-bulb approximation, and Environment and Climate Change
Canada humidex. Liljegren supports scalar and diagnostic calls plus allocating,
preallocated, and threaded aligned batches; the direct formulas are scalar and
broadcast naturally.

## Installation

Julia 1.10 or newer is required.

```sh
julia -e 'using Pkg; Pkg.add("HeatStress")'
```

HeatStress is registered in Julia General.

## Quick start

All temperatures are °C, wind is m/s, radiation is W/m², pressure is hPa, and
longitude/latitude are degrees (east/north positive). A `DateTime` is UTC;
use `ZonedDateTime` for an explicit local instant.

```julia
using Dates, HeatStress

result = liljegren_wbgt(
    30.0, 20.0, 1.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
    ghi_w_m2 = 800.0,
    pressure_hpa = 1010.0,
    partition = FixedDirectFraction(0.7),
)
result.wbgt_c

rcc = rccd167l_wbgt(
    32.0, 40.0, 2.0, DateTime(2025, 7, 1, 12), 0.0, 0.0;
    ghi_w_m2 = 800.0,
    pressure_hpa = 900.0,
)
```

For direct measures:

```julia
wbgt_with_solar_load(24.0, 35.0, 30.0)
heat_index_nws(32.0, 70.0)
wet_bulb_temperature_stull(30.0, 70.0)
humidex(30.0, 20.0)
```

For row-level input policy and root-solving information, call
`diagnose_liljegren` instead. It retains a valid component if the other solve
fails; complete WBGT is `missing` unless both components pass residual checks.

```julia
batch = liljegren_wbgt_batch(air, dew_point, wind, times, longitude, latitude;
    ghi_w_m2 = ghi, dni_w_m2 = dni, dhi_w_m2 = dhi,
    pressure_hpa = pressure,
    partition = FixedDirectFraction(direct_fraction),
    threaded = true,
)
```

Any combination of GHI, DNI, and DHI may be supplied, including none. Missing
components are reconstructed from measured component identities where
possible. With no components, daytime GHI uses the package's clear-sky
estimate. The default partition is `FixedDirectFraction(0.8)`; use
`LiljegrenClearnessFraction()` to opt into the clearness estimator.

`longitude`, `latitude`, `pressure_hpa`, optional irradiance components, and a
fixed direct-fraction value may be scalars or vectors aligned with the primary
input vectors. Use `liljegren_wbgt!` for compatible preallocated outputs.

RCC estimators use relative humidity rather than dew point, require explicit
GHI, default to `LiljegrenClearnessFraction()`, and consume model-ready wind
without implicit height conversion. `rcc_nws_wbgt` is the Dim228 + RCC-NWS
combination evaluated in RCC WP-25-001, not the complete operational NDFD
forecast preprocessing chain. See [RCC estimated WBGT](docs/src/rcc-wbgt.md).

## Numerical behaviour and limitations

The model rejects non-finite inputs, invalid coordinates, non-positive
pressure, fixed direct fractions outside `[0, 1]`, and materially inconsistent
redundant irradiance components. Negative wind/irradiance values are clamped
and recorded in diagnostics; solar forcing is zeroed at/below the geometric
horizon.
Results depend on pressure, wind treatment, timestamp convention, selected
solar method, radiation partitioning, instrument parameters, and solver
policies—do not assume equivalence with another WBGT implementation unless
these are aligned.

RCC inputs reject negative wind/radiation. RCCNL requires positive wind, while
both Dimiceli globe components apply their sourced 1 m/s floor.

Measured-component WBGT assumes representative instrument readings. NWS heat
index represents shaded conditions and omits wind, radiation, and workload.
The Stull approximation is a standard-pressure empirical fit with a restricted
temperature/humidity domain. Humidex is an environmental index, not an
individual physiological response or exposure limit.

## Provenance, validation, and citation

The implementation is expressed independently from published literature; its
primary model source is Liljegren et al. (2008), DOI
10.1080/15459620802310770. RCC estimator authority is RCC WP-25-001 (2025).
Secondary-measure authorities include OSHA, NWS,
Stull (2011), and Environment and Climate Change Canada. Equation and policy
provenance lives in
[`validation/sources.toml`](validation/sources.toml), while committed offline
fixtures validate the released surface. Familiarity with HeatStressR informed
advisory comparison interest only; it is not an implementation source or
normative test oracle.

See [the documentation](docs/src/index.md), [citation metadata](CITATION.cff),
and [contribution policy](CONTRIBUTING.md). Released benchmark numbers are
host-specific local evidence, not a universal performance guarantee or a
cross-language claim.

## AI assistance and release review

Generative AI tools assisted implementation, testing, and documentation.
Before v0.1.0 was published, the maintainer reviewed and approved the exported
runtime code, scientific equations, numerical policies, and validation
evidence. This software release review is not independent scientific peer
review.
