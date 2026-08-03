# Wind-height preprocessing

## Purpose

Add an independently usable stability-aware power-law conversion from a wind
measurement height to a reference height, and expose it as an explicit opt-in
preprocessing policy for every Liljegren API. Existing calls continue to treat
wind as already measured at 2 m and must remain numerically unchanged.

This capability is released as the additive, non-breaking v0.3.1 package
update.

## Public contract

`wind_speed_at_height` returns the adjusted scalar wind. Its diagnostic
counterpart reports supplied, reference-height and post-floor wind together
with the selected Pasquill class and exponent. Heights are metres and wind is
m/s. The standalone default is `LiljegrenStabilityPowerLaw()` with a 2 m
reference height; its optional minimum-wind floor is disabled by default.

The Liljegren scalar, component, allocating batch, preallocated batch and
diagnostic APIs accept `wind_height_m`, `wind_height_policy`, `terrain`,
`stability_class`, and `vertical_temperature_difference_c`. Their default is
`NoWindHeightAdjustment()` at 2 m. The reference height is fixed at 2 m.

Batch height, terrain, stability class and vertical temperature difference may
be shared or row-aligned. A `nothing` stability class requests automatic
classification. Missing row meteorology produces `MissingMeteorology`; an
invalid finite domain produces `InvalidDomain` before component solving.

## Scientific behaviour

The reference-height wind is

\[
u_r = u_m (z_r/z_m)^p.
\]

Automatic Pasquill classification follows the EPA solar-radiation/delta-T
(SRDT) table. Daytime uses nonnegative wind at the measurement height and
resolved GHI. Nighttime uses that wind and
`vertical_temperature_difference_c = T_upper - T_lower`. An explicitly
supplied class bypasses the classifier inputs.

Rural exponents for A--F are `0.07, 0.07, 0.10, 0.15, 0.35, 0.55`; urban
exponents are `0.15, 0.15, 0.20, 0.25, 0.30, 0.30`.

Negative high-level wind retains the existing clamp-to-zero policy before
classification. The configured Liljegren minimum-wind floor is applied after
height conversion. Both globe and natural-wet-bulb balances consume the same
recorded post-floor wind.

## Acceptance criteria

- The standalone APIs validate domains, preserve promoted floating types and
  reproduce the complete EPA classifier and exponent tables.
- Explicit stability supports nighttime conversion without vertical
  temperature difference.
- Default Liljegren calls retain existing scalar, batch and threaded values.
- All high-level entry points accept consistent scalar or aligned batch wind
  metadata without storing meteorological observations in `LiljegrenConfig`.
- Diagnostics retain raw supplied wind, both adjusted wind stages, selected
  class/exponent, explicit-class provenance, and height/floor application.
- Focused, full, threaded, quality and documentation checks pass.

## v0.3.1 audit and release gate

This specification is the approved scientific-audit package for the additive
v0.3.1 release. Its audit covers the EPA power law, exponent and SRDT tables;
the independent Julia implementation; the public preprocessing and diagnostic
contracts; default no-op compatibility; scalar/component/batch parity; and
consistent `Project.toml`/`CITATION.cff` release metadata.

The release PR is the external approval record. Required Linux minimum/current
Julia, Windows and macOS checks must pass on its final head, followed by an
authorised maintainer squash merge without another source, fixture,
scientific-contract or release-metadata change. The squash commit tree must
match the checked PR-head tree. No tag, GitHub release or General registration
may occur before that condition is satisfied.
