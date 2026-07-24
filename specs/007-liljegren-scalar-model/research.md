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
  internal FAO-56 kernel. This supplies atmospheric emissivity and the wet
  bulb's vapour-pressure term without applying public temperature-domain
  checks to solver candidates.
- Both component balances use the configured effective-wind floor. Wet-bulb
  longwave forcing remains active at night; solar forcing alone is zeroed by
  the shared horizon policy.
- A near-horizon high-radiation fixture demonstrates independent component
  retention: the globe search can be `Unbracketed` within its guardrail while
  the natural wet bulb remains valid.
- The public default pressure is converted to the call's common float type, so
  Float32 meteorology with a Float32 configuration remains Float32.
- Scalar coordinates and the FAO-56 -40--50 °C public temperature domain are
  checked before physical-property construction. Invalid observations return
  `InvalidDomain` with unattempted component diagnostics rather than throwing.
- Near-horizon direct-beam clipping is propagated through
  `direct_solar_clipped`; it is not conflated with the below-horizon radiation
  mismatch diagnostic.

## Remaining validation

- `test/fixtures/liljegren_scalar_reference.toml` records independent 256-bit
  calculations of the documented equations for daytime, supplied-radiation
  night-time, and saturated-air cases. Its generator is standalone and does
  not import HeatStress or call package kernels; component and WBGT values use
  the scalar tolerance in `spec.md`.
- The scalar test suite checks each documented scalar call with `@inferred`.
  The value-only Float64 path currently allocates 1,904 bytes after
  warm-up on the recorded host; the test enforces a conservative 4 KiB ceiling
  pending a dedicated zero-allocation redesign.
- Spec 010 still owns the broader independently sourced scientific fixture set
  and source-identifier metadata. These local fixtures establish an immediate
  independent scalar regression gate but do not replace that acceptance work.
