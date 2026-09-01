# Batch geometry preprocessing: implementation plan

1. Record fused baseline behaviour and benchmark fixed, grouped and unique
   geometry workloads.
2. Implement the private unique-term/prepared-zenith candidate and establish
   exact parity before timing.
3. Compare complete baseline/candidate execution at 100,000 and 1,000,000 rows.
4. Reject and remove the candidate if it does not pass the retention gate.
5. Retain the reusable geometry-workload benchmark extension and record the
   decision in `tasks.md`.
6. Add the missing spatial-grid cardinality and correct the solar-only harness
   so reference generation and validation are excluded from timing.
