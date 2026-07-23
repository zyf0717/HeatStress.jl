# Data model

The solver consumes a scalar residual and returns a concrete diagnostics record. Its state model is:

| Field group | Required content |
| --- | --- |
| outcome | convergence flag and `FailureReason` |
| accepted value | validated root or `missing` |
| candidate | last candidate retained only for diagnostics |
| residuals | Kelvin-scale candidate validation residual plus lower/upper location residuals in the documented native equation units |
| bracket history | initial and final lower/upper bounds |
| work | iteration and evaluation counts |
| policy | root and residual tolerances used |

A residual-validation failure must never promote the candidate into the accepted component value.
