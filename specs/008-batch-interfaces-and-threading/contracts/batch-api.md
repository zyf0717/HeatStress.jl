# Batch API contract

Allocating and preallocated batch APIs must produce row-equivalent results. Threaded execution must preserve input order, status, missingness and numerically equivalent values relative to serial execution. `!` methods own no output allocation beyond documented fixed overhead.

Alignment, scalar expansion and coordinate preprocessing behavior must be documented and tested.
