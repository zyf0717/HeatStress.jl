# Liljegren scalar model: research

## Required sources

- Liljegren et al. (2008), all model equations and assumptions.
- Validated components from 004–006.

The authoritative detail and citations remain in `spec.md`; software implementations are not scientific authorities.

## Findings to record

- Equation, coefficient, policy or design decision.
- Source identifier, section/equation and units.
- Independent validation method and tolerance.

## Findings and decisions

- Scalar preprocessing composes the normalized meteorology policy with
  Spencer solar zenith. The public zenith is degrees and is converted to
  radians only at the prepared-meteorology boundary. `DateTime` remains UTC;
  `ZonedDateTime` is reduced to the same UTC instant.
- Actual vapour pressure is evaluated from normalized dew point using the
  private pressure-enhanced Buck kernel. Dew point and wet-bulb candidates are
  restricted to its published liquid/supercooled-liquid range; air temperature
  is not independently restricted to that range.
- Both component balances use the configured effective-wind floor. Wet-bulb
  longwave forcing remains active at night; solar forcing alone is zeroed by
  the shared horizon policy.
- A near-horizon high-radiation fixture demonstrates independent component
  retention: the globe search can be `Unbracketed` within its guardrail while
  the natural wet bulb remains valid.
- The scalar common float type is determined from meteorology, pressure,
  coordinates, direct fraction and configuration before any validation return.
  The documented Float64 pressure default therefore produces Float64 results;
  callers that require Float32 pass `pressure_hpa = 1010f0` explicitly.
- Scalar coordinates and the Buck -40--50 °C dew-point domain are checked
  before physical-property construction. Invalid observations return
  `InvalidDomain` with unattempted component diagnostics rather than throwing.
- Near-horizon direct-beam clipping is propagated through
  `direct_solar_clipped`; it is not conflated with the below-horizon radiation
  mismatch diagnostic.

## Remaining validation

- `test/fixtures/liljegren_scalar_reference.toml` records independent 256-bit
  calculations of the documented equations for daytime, supplied-radiation
  night-time, saturated-air and sub-minute timestamp cases. Its standalone
  generator constructs every BigFloat constant under a 256-bit local precision
  scope, uses seconds and milliseconds in solar time, and records generator,
  source and schema metadata. Fresh-process regeneration is tested at two
  ambient BigFloat precisions.
- The scalar test suite checks each documented scalar call with `@inferred`.
  The common physical preparation and component outcomes are materialized as
  either `WBGTResult` or `DiagnosticWBGTResult`; no diagnostic structs are
  built on the value-only path. A warmed direct Float64 value call allocates
  64 bytes on the recorded host; the regression ceiling is 1 KiB.
- Spec 010 still owns the broader independently sourced scientific fixture set
  and source-identifier metadata. These local fixtures establish an immediate
  independent scalar regression gate but do not replace that acceptance work.
