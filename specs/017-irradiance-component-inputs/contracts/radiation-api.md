# Radiation API contract

All irradiance names encode orientation and units: `ghi_w_m2`, `dni_w_m2`,
and `dhi_w_m2`. A `DateTime` is UTC and a `ZonedDateTime` is converted to UTC
before geometry and reconstruction.

Scalar optional components accept `nothing`, `missing`, or `Real`; `nothing`
and `missing` both mean unavailable. Batch components accept `nothing`, a
shared `Real`/`Missing`, or a row-aligned vector with concrete real values
optionally unioned with `Missing`.

The fixed partition value follows the same scalar/aligned expansion rules in
batch calls. Inconsistent lengths or broad/non-real element types fail before
preallocated outputs are mutated.
