# Physical kernels

## Purpose

Implement the pure heat-transfer and residual equations used by globe and natural wet-bulb solvers. These functions must not perform root finding, public validation or threading.

## Required kernel groups

### Air-property and transfer kernels

Implement the physical kernels required by the published Liljegren formulation, including:

- sphere heat-transfer coefficient;
- cylinder heat-transfer coefficient;
- air viscosity;
- thermal conductivity where used;
- diffusivity and diffusivity coefficient;
- atmospheric emissivity;
- saturation vapour pressure.

Recommended internal names:

```julia
_heat_transfer_sphere_air
_heat_transfer_cylinder_air
_air_viscosity
_air_diffusivity
_atmospheric_emissivity
_saturation_vapour_pressure
```

### Globe residuals

Implement two distinct residual concepts and name them clearly:

1. fourth-power energy residual used to locate the root;
2. Kelvin-scale fixed-point residual used for final acceptance.

Recommended names:

```julia
_globe_energy_residual_k4(...)
_globe_fixed_point_residual_k(...)
```

Do not collapse them. The selected mathematical formulation locates the root in the fourth-power energy equation and validates using the Kelvin-scale residual.

### Natural wet-bulb residual

Implement the signed heat-balance residual for the wick model:

```julia
_natural_wet_bulb_residual(...)
```

The residual function must receive a precomputed immutable parameter struct where this reduces repeated calculations.

## Parameter structs

To reduce long positional argument lists and make unit meaning explicit, define internal immutable structs such as:

```julia
struct GlobeBalance{T<:AbstractFloat}
    air_temperature_k::T
    pressure_hpa::T
    effective_wind_m_s::T
    longwave_term::T
    solar_term::T
    globe_diameter_m::T
    globe_emissivity::T
end

struct WetBulbBalance{T<:AbstractFloat}
    air_temperature_k::T
    pressure_hpa::T
    effective_wind_m_s::T
    vapour_pressure::T
    air_density::T
    air_viscosity::T
    diffusivity_coefficient::T
    longwave_term::T
    solar_term::T
    radiation_enabled::Bool
    wick_diameter_m::T
    wick_emissivity::T
end
```

The exact fields may change if formula inspection proves different, but structs must remain immutable and concrete.

## Solar-forcing and horizon policy

Do not inherit undocumented zenith/radiation caps from prior software. Derive the normal solar-forcing treatment from the paper and its cited sources.

If numerical protection is required near the horizon:

1. identify the singular or ill-conditioned term;
2. document the physical and numerical reason for intervention;
3. define one named policy/helper shared by Tg and Tnwb;
4. add boundary tests around every threshold;
5. expose a diagnostic when supplied radiation is inconsistent with computed solar geometry;
6. distinguish physical night-time zeroing from numerical clipping.

Historical thresholds remembered from HeatStressR may be used to design stress tests, but must not become defaults unless independently justified and documented. If a compatibility policy is later useful, isolate it behind an explicitly named non-default mode.

## Implementation rules

- scalar kernels only;
- no allocations after parameter construction;
- no closures in the deepest residual evaluation if a callable struct or direct function is clearer;
- no global counters; evaluation counts belong to the solver;
- no mutation of user inputs;
- no warnings from kernels;
- non-finite arithmetic should naturally produce non-finite residuals for classification by the solver;
- avoid algebraic rewrites until independent validation tests pass;
- add comments when literal constants differ from common textbook values.

## Tests

Create independent physical-kernel tests:

- scalar values at 270, 300 and 340 K;
- zero, low and ordinary wind;
- sphere and cylinder coefficients;
- diffusivity coefficient decomposition;
- globe energy residual reconstructed independently from terms;
- fixed-point residual equals zero near accepted high-precision roots;
- wet-bulb residual sign changes across independently constructed brackets;
- zenith correction branch boundaries;
- no allocations for repeated direct residual evaluations after compilation;
- `@inferred` for Float64 kernels.

Use independently sourced fixture rows for at least 20 ordinary and boundary combinations.

## Acceptance criteria

- all kernel fixtures pass within `rtol=1e-12, atol=1e-12` where calculations are directly equivalent Float64 arithmetic; relax only with documented reason;
- kernels are independently callable in tests;
- root-solving code is absent from kernel files;
- no kernel emits warnings or throws for a merely non-finite intermediate residual.

## Suggested commit

`feat: implement Liljegren physical kernels`

