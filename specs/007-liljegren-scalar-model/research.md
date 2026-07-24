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

## Remaining validation

- Spec 010 owns the independently sourced/high-precision scalar fixture set.
  The present tests establish API, policy, diagnostic, Float32, and
  partial-failure invariants but are not a substitute for that scientific
  acceptance evidence.
