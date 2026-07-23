# Scalar model contract

The scalar Liljegren path computes globe temperature and natural wet-bulb independently. Complete WBGT is returned only if both accepted component roots are available. If one component fails, retain the valid other component and expose the failure through diagnostics.

Configuration policies and physical parameters are explicit; no behavior is inferred from legacy compatibility flags.
