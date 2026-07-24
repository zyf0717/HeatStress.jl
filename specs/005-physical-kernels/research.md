# Physical kernels: research

## Sources selected

- Liljegren et al. (2008), doi:10.1080/15459620802310770: model balance,
  wick Nusselt correlation, instrument geometry and optics.
- Bird, Stewart & Lightfoot (2006), *Transport Phenomena*, 2nd ed.: dilute-gas
  viscosity (eq. 1.4-14), sphere convection (eqs. 14.2-3, 14.4-5), and the
  critical-property water-vapour diffusivity correlation (eq. 17.2-1).
- Oke (1987), *Boundary Layer Climates*, 2nd ed.: atmospheric emissivity
  (p. 374, eq. 2) and the latent-heat fit (table A3.1).
- Kannuluik & Carman (1951), thermal conductivity fit as reproduced with its
  CGS-to-SI conversion by Hall et al. (2022), eq. 10.
- Hall et al. (2022), *Weather and Climate Extremes* 35, 100420,
  doi:10.1016/j.wace.2022.100420: independent published transcription of the
  complete Liljegren balances and unit conversions (eqs. 6--23).

## Findings and decisions

- Air properties use Kelvin and pressure hPa.  `_air_diffusivity` returns
  m² s⁻¹; `_diffusivity_coefficient` is dimensionless
  `(M_w/M_a)(Pr/Sc)^0.56` and is precomputed in `WetBulbBalance`.
- `GlobeBalance.longwave_term` and `.solar_term` are K⁴.  Wet-bulb forcing
  fields are W m⁻².  This makes units explicit at the residual boundary.
- The globe root equation is fourth-power energy balance; acceptance is its
  separate Kelvin fixed-point residual.  The wet-bulb residual is signed as
  candidate minus fixed-point equilibrium temperature.
- Direct horizontal-beam geometry is singular as zenith approaches 90°:
  `1/(2cos θ)` for the globe and `tan θ/π` for the wick.  No undocumented
  near-horizon cap is applied.  At/after the geometric horizon the shared
  helper zeroes only direct forcing; diffuse radiation remains.  Spec 007
  must surface an input diagnostic if supplied direct radiation conflicts with
  computed night geometry.
- The residual layer calls the spec-004 FAO-56 formula through its unchecked
  internal kernel so non-finite candidate temperatures yield non-finite
  residuals rather than a public-input `ArgumentError`.

## Validation method

- Hard-coded Float64 fixtures are calculated from the cited equations and
  published constants, independently of package kernel calls.
- Boundary tests cover 90° direct-beam removal, zero/low/ordinary wind,
  fourth-power versus Kelvin residuals, and wet-bulb sign brackets.
