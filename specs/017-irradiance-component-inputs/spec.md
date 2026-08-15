# Irradiance component inputs

## Purpose

Replace the released positional-global-radiation interface with a v0.3 API that
accepts any row-wise combination of global horizontal irradiance (GHI), direct
normal irradiance (DNI), and diffuse horizontal irradiance (DHI), including no
supplied component. Resolve the horizontal shortwave forcing and direct
fraction before invoking the unchanged Liljegren sensor balances.

## Public contract

Scalar calls take air temperature, dew point, wind, time, longitude and
latitude positionally. Irradiance components are optional keywords in W/m²:

```julia
liljegren_wbgt(
    air_temperature_c,
    dew_point_c,
    wind_speed_m_s,
    time,
    longitude_deg,
    latitude_deg;
    ghi_w_m2 = nothing,
    dni_w_m2 = nothing,
    dhi_w_m2 = nothing,
    partition = FixedDirectFraction(0.8),
    pressure_hpa = 1010,
    config = LiljegrenConfig(),
)
```

The same replacement applies to `diagnose_liljegren`, `globe_temperature`,
`natural_wet_bulb_temperature`, `liljegren_wbgt_batch`, `liljegren_wbgt!`,
and `diagnose_liljegren_batch`. The old positional-radiation signatures and
standalone `direct_fraction` keyword are removed in v0.3.

`nothing` means that a component is not supplied. In batch APIs, each
component may be `nothing`, a shared real scalar, or a row-aligned vector whose
elements are `Real` or `Missing`; a `missing` component is unavailable for that
row and is reconstructed. Missing primary meteorology retains the existing
missing-row behaviour.

Partition policies are explicit:

```julia
FixedDirectFraction(0.8)
LiljegrenClearnessFraction()
```

`FixedDirectFraction` accepts a real scalar for scalar calls and a real scalar
or row-aligned vector for batch calls. Its default is 0.8. Values must be
finite and lie in `[0, 1]`.

## Radiation identities and units

With solar zenith `θ`, direct horizontal irradiance is

\[
BHI = DNI\cos\theta,
\]

and coincident components obey

\[
GHI = DHI + BHI.
\]

The direct fraction consumed by the Liljegren balances is horizontal:

\[
f_\mathrm{dir} = BHI/GHI.
\]

It is not `DNI/GHI`. When resolved GHI is zero, the operational direct fraction
is zero.

## Resolution matrix

Supplied finite values are retained after the existing negative-to-zero input
normalisation.

| Supplied | Resolution |
| --- | --- |
| GHI, DNI, DHI | Validate closure; use supplied GHI and `DNI*cos(θ)/GHI`. |
| GHI, DNI | Derive DHI from closure. |
| GHI, DHI | Derive BHI and the direct fraction; derive DNI only away from the direct-beam cutoff. |
| DNI, DHI | Derive GHI exactly from closure. |
| GHI only | Split using the selected partition policy. |
| DNI only, fixed | Preserve DNI and solve GHI/DHI from the fixed fraction; positive DNI with fraction zero is invalid. |
| DHI only, fixed | Preserve DHI and solve GHI/DNI from the fixed fraction; positive DHI with fraction one is invalid. |
| none | Estimate clear-sky GHI and split it with the selected partition policy. |

For `LiljegrenClearnessFraction`, GHI supplies the clearness calculation. A
DNI-only or DHI-only row preserves the supplied component and obtains the
complementary horizontal component from the selected clear-sky estimate.

Redundant components pass when

\[
|GHI-DHI-DNI\cos\theta|
\le \max(a,\tau I_{0h}),
\]

where the defaults are `a = 20 W/m²` and `τ = 0.03`. Larger disagreement
returns `InvalidDomain`, records a closure mismatch, and does not invoke either
solver. Small negative derived components within tolerance are normalised to
zero and diagnosed as adjusted; disagreement is never silently reassigned to
another supplied component.

## Clear-sky and partition models

When GHI is absent and a clear-sky magnitude is required, use the
Kasten--Czeplak form:

\[
GHI_\mathrm{clear}=\max(0,910\cos\theta-30)\ \mathrm{W\,m^{-2}}.
\]

The Liljegren clearness policy uses the FAO-56 inverse relative Earth--Sun
distance

\[
d_r=1+0.033\cos(2\pi J/365)
\]

and

\[
I_{0h}=1367d_r\max(0,\cos\theta).
\]

For positive GHI and `I0h`,

\[
k_t^*=GHI/I_{0h}
\]

and

\[
f_\mathrm{dir} =
\operatorname{clamp}\left(
\exp(3-1.34k_t^*-1.65/k_t^*),0,1
\right).
\]

The exponential is sourced equation 13; the final `[0, 1]` clamp is a package
physical-output policy owned by spec 022.

No cap is applied to the clearness ratio. Supplied or reconstructed GHI is
never capped against top-of-atmosphere irradiance; only the resulting physical
fraction is clamped to `[0,1]`.

## Horizon policy

At and below the geometric horizon, all resolved solar forcing is zero.
Positive supplied components set the existing solar-geometry mismatch flag.
Liljegren's `89.5°` zenith cutoff remains in force above the horizon and is
reported separately.

## Diagnostics

Scalar diagnostic results contain nested `IrradianceDiagnostics`; batch
diagnostics contain its structure-of-arrays equivalent. They report:

- resolved GHI, DNI, DHI and direct fraction;
- clear-sky GHI where evaluated;
- which components were supplied, estimated, or negative-clamped;
- whether a derived component was adjusted to zero;
- partition policy;
- closure residual and accepted tolerance;
- closure mismatch.

Failure diagnostics retain available normalised inputs and leave unresolved
values `missing`.

## Acceptance criteria

- all eight component-presence combinations are implemented for scalar and
  batch calls;
- component identities and the horizontal direct-fraction definition are
  explicit and tested;
- no-input daytime calls represent estimated clear-sky full sun; no-input
  night calls have zero forcing;
- supplied GHI is never capped by a TOA or clear-sky value;
- inconsistent redundant inputs fail before solver execution;
- fixed fractions may vary by row in batch calls;
- scalar, serial batch, preallocated batch and threaded batch paths agree;
- Float32/Float64 behaviour, missing component reconstruction, offset axes,
  horizon cases and policy singularities are covered;
- existing scientific fixtures are invoked through the new explicit inputs
  without changing their recorded reference values;
- documentation and provenance identify which values are observed, derived,
  and empirical.
