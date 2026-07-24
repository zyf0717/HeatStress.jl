# Liljegren pipeline

The public Liljegren calls implement outdoor WBGT as a coupled set of two
independent temperature balances: black-globe temperature and natural wet-bulb
temperature. Their accepted values are combined as

```math
WBGT = 0.7 T_{nwb} + 0.2 T_g + 0.1 T_a.
```

## Preparation

The scalar boundary fixes a common floating type and converts the supplied
configuration. Meteorology is validated and normalised before any solve:
dew-point policy is applied, negative wind/radiation are flagged and clamped,
and the timestamp/coordinates provide solar zenith. `DateTime` is UTC;
`ZonedDateTime` is converted to its UTC instant.

## Component balances

Both balances use the prepared atmosphere, radiation partition, surface
albedo, and the configured wind floor. The globe balance uses globe diameter,
albedo, and emissivity; the wet-bulb balance uses wick geometry and its heat
and mass transfer terms. Each balance is solved with the shared bracketed
solver and then independently checked against its residual tolerance.

## Results and diagnostics

A rejected input produces unattempted component diagnostics. A failed
component stays `missing`, while a successful independent component is
retained. WBGT itself is available only when both components have accepted
roots. `diagnose_liljegren` exposes input adjustments, solver brackets,
candidate roots, validation residuals, and failure reasons.

The package implementation is independently expressed from published
literature; see [Scientific provenance](@ref) for source policy.
