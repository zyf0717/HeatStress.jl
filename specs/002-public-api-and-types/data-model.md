# Data model

| Type family | Responsibility | Invariants |
| --- | --- | --- |
| `SolverConfig{T}` | Root tolerances and iteration cap | positive tolerances; positive iteration cap |
| `LiljegrenConfig{T}` | Physical and policy configuration | valid albedo, diameter, wind floor and policies |
| `WBGTResult{T}` | Scalar value components | complete WBGT only when both components validate |
| `SolverDiagnostics{T}` | Solver trace and failure classification | candidate may exist while value remains `missing` |
| `DiagnosticWBGTResult{T}` | Scalar result plus input/solver diagnostics | input status and component diagnostics remain explicit |
| `WBGTBatchResult` | Structure-of-arrays batch result | row alignment across all arrays |

Batch diagnostics must also be structure-of-arrays and preserve row order. Do not use `Vector{Any}`, dictionaries or per-row diagnostic object allocation in hot paths.
