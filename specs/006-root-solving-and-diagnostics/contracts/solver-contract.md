# Solver contract

A solve attempt reports `NoFailure`, `Unbracketed`, `NonFiniteResidual`, `ResidualValidationFailed` or `IterationLimit` as applicable. Acceptance requires both the solver stop condition and the component’s Kelvin-scale validation residual within configured tolerance. An unaccepted candidate is diagnostic-only.

The solver must report initial/final brackets, native-equation endpoint residuals, evaluations and iterations deterministically. Component wrappers report the separate Kelvin-scale validation residual.
