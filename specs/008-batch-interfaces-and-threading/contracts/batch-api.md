# Batch API contract

Allocating and preallocated batch APIs must produce row-equivalent results. Threaded execution must preserve input order, status, missingness and numerically equivalent values relative to serial execution. `!` methods own no output allocation beyond documented fixed overhead.

Alignment, scalar expansion and coordinate preprocessing behavior must be documented and tested.

Primary meteorology and time inputs are equal-length `AbstractVector`s. Each
secondary input is either a scalar (`Real` or `missing`) or an equal-length
vector, accessed by ordinal row without materialization. Allocating calls
return ordinary 1-based `Vector{Union{Missing,T}}`; `!` calls validate every
output length and element type before writing. `threaded=true` uses Julia
threads only and preserves serial row order and values.
