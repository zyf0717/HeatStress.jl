# RCC WBGT estimators: source audit

## Authorities

- Range Commanders Council Meteorology Group, *Assessment of Estimation
  Methods for the Wet-bulb Globe Temperature*, RCC WP-25-001, April 2025.
- Dimiceli and Piltz, *Estimation of Black Globe Temperature for Calculation
  of the WBGT Index*, cited by WP-25-001.
- Boyer, *NDFD Wet Bulb Globe Temperature Algorithm and Software Design*, used
  only to identify preprocessing excluded from this package contract.

The implementation independently expresses equations and policies from these
documents. No third-party implementation is used as source material.

## Resolved blockers

### RCCNL wind

WP-25-001 equation 9 divides its radiation and wet-bulb-depression numerator
by `u^0.15`. The report specifies no minimum or replacement value for RCCNL,
unlike the explicit 1 m/s floor stated for Dimiceli globe calculations.
Therefore RCCNL's sourced mathematical domain is `u > 0`; zero and negative
wind are rejected. No Liljegren wind floor is imported.

### Dim167L constants and policies

The paragraph defining the evaluated Dimiceli family fixes globe emissivity at
the Liljegren value 0.95, surface albedo at the Dimiceli value 0.2, direct
fraction from Liljegren equations 13-14, and a 1 m/s wind floor. Dim167L uses
WP-25-001 equation 4 for `B` and `h_day = 0.167`; it does not switch surface
albedo to HeatStress's configurable Liljegren default. Dim228 uses equation
3's original heat-gain form and `h_day = 0.228`. Both use `h_night = 0` and the
87-degree boundary. The exact-boundary ownership is fixed as night at
`zenith >= 87°`, consistent with the report's threshold terminology and the
direct-beam term being undefined as the boundary approaches the horizon.

The Dimiceli linearization is in Celsius: `256000 = 4(40°C)^3` and
`7680000 = 3(40°C)^4`; consequently the `T_a^4`, `C*T_a`, and returned `T_g`
terms use Celsius exactly as equations 3-4 label them. The Dimiceli value
`σ = 5.67e-8` is retained rather than silently substituting the package's
Liljegren-specific `5.6696e-8` constant.

### Meaning of NWS

WP-25-001 Table 5 defines the evaluated NWS result as Dim228 globe temperature
plus equation 8 RCC-NWS natural wet bulb. Boyer's NDFD chain additionally
estimates solar flux from a daily curve and cloud cover, caps direct fraction,
downscales 10 m wind from land-cover roughness, reduces mean-sea-level pressure
to station pressure, and uses gridded albedo. Those steps are not inputs to or
requirements of `rcc_nws_wbgt`; the public name describes only the RCC Table 5
component combination.

## API decisions owned by HeatStress

- Named functions avoid hidden model switching.
- Relative humidity is native and GHI is mandatory.
- Scalar model results reuse `WBGTResult`; aligned batches reuse
  `WBGTBatchResult`.
- Component functions accept the meteorological values required to evaluate
  their source equations and naturally support Julia dot broadcasting.
- No wind-height transform occurs inside RCC model APIs.
- At exactly 87 degrees, the night coefficient owns the threshold.

## Deferred evidence

The 2021 observation data and complete preprocessing inputs have not been
located as a stable public dataset. Appendix A aggregate statistics are
context, not unit-test oracles.
