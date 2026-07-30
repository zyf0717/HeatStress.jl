# Liljegren pipeline

The public Liljegren calls implement outdoor WBGT as a coupled set of two
independent temperature balances: black-globe temperature and natural wet-bulb
temperature. Their accepted values are combined as

```math
WBGT = 0.7 T_{nwb} + 0.2 T_g + 0.1 T_a.
```

## Preparation

The scalar boundary fixes a common floating type and converts the supplied
configuration. Timestamp and coordinates provide solar zenith, then the
available GHI/DNI/DHI components are reconciled. Measured component identities
take precedence; underdetermined inputs use the selected partition policy, and
no-input daytime rows use clear-sky GHI. Meteorology is then validated and
normalised before either solve. `DateTime` is UTC; `ZonedDateTime` is converted
to its UTC instant.

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
candidate roots, validation residuals, failure reasons, and nested irradiance
provenance. A closure mismatch rejects the row before component solving.

The package implementation is independently expressed from published
literature; see [Scientific provenance](@ref) for source policy.
