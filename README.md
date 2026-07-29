# HeatStress.jl

HeatStress.jl is an independent MIT-licensed Julia package for heat-stress
measures. It implements the Liljegren outdoor wet-bulb globe temperature
(WBGT) model, measured-component WBGT, the US National Weather Service heat
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
    30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
    pressure_hpa = 1010.0, direct_fraction = 0.7,
)
result.wbgt_c
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
batch = liljegren_wbgt_batch(air, dew_point, wind, radiation, times, longitude, latitude;
                              pressure_hpa = pressure, direct_fraction = direct,
                              threaded = true)
```

`longitude`, `latitude`, `pressure_hpa`, and `direct_fraction` may be scalars
or vectors aligned with the primary input vectors. Use `liljegren_wbgt!` when
you own compatible output arrays and need to avoid replacement output arrays.

## Numerical behaviour and limitations

The model rejects non-finite inputs, invalid coordinates, non-positive
pressure, and direct fractions outside `[0, 1]`. Negative wind/radiation are
clamped and recorded in diagnostics; supplied radiation is zeroed at/below the
geometric horizon. The direct/diffuse radiation split is an explicit input.
Results depend on pressure, wind treatment, timestamp convention, selected
solar method, radiation partitioning, instrument parameters, and solver
policies—do not assume equivalence with another WBGT implementation unless
these are aligned.

Measured-component WBGT assumes representative instrument readings. NWS heat
index represents shaded conditions and omits wind, radiation, and workload.
The Stull approximation is a standard-pressure empirical fit with a restricted
temperature/humidity domain. Humidex is an environmental index, not an
individual physiological response or exposure limit.

## Provenance, validation, and citation

The implementation is expressed independently from published literature; its
primary model source is Liljegren et al. (2008), DOI
10.1080/15459620802310770. Secondary-measure authorities include OSHA, NWS,
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
