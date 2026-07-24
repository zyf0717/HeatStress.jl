# Scalar model contract

The scalar Liljegren path computes globe temperature and natural wet-bulb independently. Complete WBGT is returned only if both accepted component roots are available. If one component fails, retain the valid other component and expose the failure through diagnostics.

Configuration policies and physical parameters are explicit; no behavior is inferred from legacy compatibility flags.

Each public scalar function has explicit scalar argument signatures. Pressure
defaults to `DEFAULT_PRESSURE_HPA`; `missing` pressure is classified as
`MissingMeteorology`, while `nothing` is not an input mode and raises
`MethodError`. The common floating type is fixed before input-status returns,
so accepted and rejected observations with the same typed arguments have the
same result parameter.

The value-only and diagnostic calls share normalized meteorology, physical
balances, bracket policy and residual acceptance. They differ only when shared
component outcomes are materialized into `WBGTResult` or diagnostics.
