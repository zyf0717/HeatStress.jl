# Solver contract

A solve attempt reports `NoFailure`, `Unbracketed`, `NonFiniteResidual`, `ResidualValidationFailed` or `IterationLimit` as applicable. Acceptance requires both the solver stop condition and a final residual within configured tolerance. An unaccepted candidate is diagnostic-only.

The solver must report initial/final brackets, residuals, evaluations and iterations deterministically.
