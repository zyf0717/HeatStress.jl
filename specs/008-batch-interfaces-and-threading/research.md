# Batch interfaces and threading: research

## Required sources

- Julia threading and array-performance documentation.
- Scalar behavior and data semantics from 002 and 007.

The authoritative detail and citations remain in `spec.md`; software implementations are not scientific authorities.

## Findings to record

- Equation, coefficient, policy or design decision.
- Source identifier, section/equation and units.
- Independent validation method and tolerance.

## Open questions

- Solar reuse remains deferred: v0.1 uses the canonical scalar solar path per
  row until profiling shows grouped-time preprocessing is material.
- Diagnostic batches use package-owned structure-of-arrays vectors, avoiding
  per-row diagnostic objects in the returned layout. Threaded loops write only
  their own ordinal row and retain no shared counters.
- The initial 10,000-row preallocated benchmark on two available threads was
  host-specific evidence only (0.0455 s serial; 0.0235 s threaded median).
  It establishes a baseline for future grouped-solar and scalar-core allocation
  work, rather than a portable performance claim.
