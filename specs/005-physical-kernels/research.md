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

- Air properties use Kelvin and pressure hPa. `_air_diffusivity` returns
  m² s⁻¹; `_diffusivity_coefficient` is dimensionless
  `(M_w/M_a)(Pr/Sc)^0.56` and is recomputed at every candidate/air film
  temperature.
- `GlobeBalance.longwave_term` and `.solar_term` are K⁴.  Wet-bulb forcing
  fields are W m⁻².  This makes units explicit at the residual boundary.
- The globe root equation is fourth-power energy balance; acceptance is its
  separate Kelvin fixed-point residual. `_globe_energy_residual_k4` subtracts
  the raw radicand directly; only the Kelvin residual applies a fourth root.
  The wet-bulb residual is signed as candidate minus fixed-point equilibrium
  temperature.
- Direct horizontal-beam geometry is singular as zenith approaches 90°:
  `1/(2cos θ)` for the globe and `tan θ/π` for the wick. The package applies
  Liljegren's `MINIMUM_DIRECT_SOLAR_ELEVATION_RAD = 0.5°` rule: at and below
  that positive elevation it discards direct forcing, retains diffuse
  forcing, and returns a helper flag distinct from physical night-time
  zeroing. The scalar diagnostic path in spec 007 must carry that flag when
  constructing the public result.
- Internal solar zenith is radians, matching `_PreparedMeteorology` and the
  spec-003 unit contract. Wet-bulb transport properties and latent heat are
  evaluated at `(Twick + Tair)/2` for each residual candidate.
- The residual layer calls the private pressure-enhanced Buck kernel and is
  evaluated only on its closed `[-40, 50] °C` domain.

## Validation method

- Hard-coded Float64 fixtures record raw globe radicands, fourth-power energy
  residuals and fixed-point roots separately from the kernel assertions.
- Boundary tests cover the numerical direct-forcing threshold, physical
  horizon zeroing, zero/low/ordinary wind, fourth-power versus Kelvin
  residuals, and wet-bulb sign brackets.
