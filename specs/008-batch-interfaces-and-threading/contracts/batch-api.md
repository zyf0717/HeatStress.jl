# Batch API contract

Allocating and preallocated batch APIs must produce row-equivalent results. Threaded execution must preserve input order, status, missingness and numerically equivalent values relative to serial execution. `!` methods allocate no replacement result arrays; current total allocations still scale with rows because each iteration uses the canonical scalar value path. Allocation counts and bytes are measured by `benchmark/batch_e2e.jl` rather than claimed as fixed overhead.

Alignment, scalar expansion and coordinate preprocessing behavior must be documented and tested.

Primary meteorology inputs are equal-length `AbstractVector`s with concrete
numeric element types, optionally unioned with `Missing`; time vectors permit
only `DateTime`, `ZonedDateTime` and `Missing`. Longitude and latitude are
non-missing `Real` scalars or equal-length concrete-real vectors. Pressure and
direct fraction are numeric scalars or equal-length numeric vectors, optionally
unioned with `Missing`. All vectors are accessed by ordinal row without
materialization, so their axes may differ.

Allocating calls return ordinary 1-based `Vector{Union{Missing,T}}`. `!` calls
validate every input, output length, output element capability and aliasing
relationship before writing; valid output arrays may have different axes and
are written in their own ordinal order. Output-output aliases and output-input
aliases are rejected. `threaded=true` uses Julia threads only and preserves
serial row order and values. Value-only v0.1 calls emit no aggregate warning;
missing values retain failed or rejected rows and `diagnose_liljegren_batch`
provides row-level reasons. Diagnostic tolerance arrays are intentionally not
duplicated per row: root and residual tolerances are supplied by the common
batch configuration.
