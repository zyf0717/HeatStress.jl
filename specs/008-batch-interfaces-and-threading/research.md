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

- Select preprocessing cache keys and ownership without mutable global state.
- Set diagnostics-memory policy for high-throughput calls.
