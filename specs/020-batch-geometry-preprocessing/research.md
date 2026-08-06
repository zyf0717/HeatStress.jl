# Batch geometry preprocessing: research

## Existing baseline

Spec 008 uses worker-local fused geometry and solving. Spec 011 permits a
prepared-zenith follow-up only after profiling, requires both phases to be
parallel for threaded calls, and requires complete end-to-end timing including
grouping and scattering.

The scalar path computes Spencer time terms in Float64, computes zenith in
degrees, applies `deg2rad`, then converts to the promoted model type. The
existing cached-coordinate formula produced bit-identical results to the
scalar formula for 8,295 sampled time/location combinations; the refactor must
preserve that operation order.

## Design constraints

- Cache keys are UTC `DateTime` instants and `(Float64, Float64)` coordinate
  pairs, matching the public solar-geometry conversion boundary.
- Cache construction is local to one public call. Threaded phases only read the
  completed caches and write disjoint row slots.
- Geometry failure state must be stored separately from zenith values so
  missing time and invalid location remain row-level diagnostics rather than
  whole-batch exceptions.

## Findings

- The candidate preserved exact scalar/batch and serial/threaded results after
  its geometry phases were made deterministic.
- At 100,000 fixed-station rows, seven-sample medians showed improvements of
  1.0% for preallocated serial, 2.7% for allocating serial and 1.2% for
  four-thread execution. These differences were below the 5% gate.
- At 1,000,000 rows, fixed-workload serial/threaded medians changed from
  5.173/1.662 seconds to 5.302/1.672 seconds. Grouped-workload medians changed
  from 4.851/1.514 seconds to 4.872/1.502 seconds.
- The larger workload confirmed no material end-to-end benefit. Small deltas
  were sensitive to host conditions and none approached the retention gate.

## Decision

Reject the prepared-geometry candidate and retain the worker-local fused path.
Keep the benchmark's fixed, grouped and unique workloads for future profiling.
