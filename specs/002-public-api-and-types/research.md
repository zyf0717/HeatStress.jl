# Public API and types: research

## Required sources

- Julia type and multiple-dispatch design guidance.
- Scientific/public-policy decisions recorded by 000 and 003.

The authoritative detail and citations remain in `spec.md`; software implementations are not scientific authorities.

## Findings to record

- Equation, coefficient, policy or design decision.
- Source identifier, section/equation and units.
- Independent validation method and tolerance.

## Open questions

- Decide whether optional string-time convenience methods are warranted after core completion.

## Resolved decisions

- **Default dew-point policy: `ClampDewPoint`.** A dew point above air temperature is
  physically inconsistent. Clamping the dew point to saturation preserves the supplied
  air temperature, avoids silently reinterpreting the measurement columns, and is
  deterministic for routine data-quality defects. The diagnostic result explicitly
  records the adjustment. `SwapAirAndDewPoint` remains available only as an opt-in
  legacy-data repair policy; `RejectInvalidDewPoint` remains available for strict
  ingestion workflows.
