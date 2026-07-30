# Irradiance component data model

`FixedDirectFraction` owns an explicit scalar or batch-aligned fraction.
`LiljegrenClearnessFraction` is stateless.

`IrradianceDiagnostics` is nested in the scalar Liljegren diagnostic and
contains nullable resolved values plus explicit supplied/estimated/clamped and
closure fields. `IrradianceDiagnosticsBatch` stores one aligned vector per
field. The masks are represented as named booleans rather than public bit
encodings.

Internal prepared meteorology contains resolved GHI and horizontal direct
fraction only; DNI and DHI are reconciliation/diagnostic inputs and do not
enter the sensor balances independently.
