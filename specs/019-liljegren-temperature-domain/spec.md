# Liljegren temperature-domain correction

## Purpose

Remove the package-owned `[-40, 50] °C` rejection from the high-level
Liljegren WBGT pathway. The interval is not a sourced validity domain of the
Liljegren model and must not prevent physically representable rows from
reaching derived-state validation and component solving.

This correction is released as the backward-compatible `v0.3.2` patch.

## Requirements

- Accept finite air and dew-point temperatures when the values resolved by
  `DewPointPolicy` are both strictly above absolute zero.
- Do not clamp either temperature to the superseded interval.
- Preserve clamp, swap, reject and tolerance behavior for dew point above air
  temperature.
- Before component solving, require finite positive vapour pressure, density,
  viscosity, thermal conductivity, air diffusivity and mass-transfer ratio;
  vapour pressure must also be below total pressure.
- Classify an invalid derived state as `InvalidDomain` with both component
  solvers unattempted.
- Preserve the standalone public psychrometric-helper contract in spec 004.
- Treat execution outside `[-40, 50] °C` as calculation support, not validated
  scientific accuracy.

## Acceptance criteria

- No high-level Liljegren API rejects a row solely because air or dew point is
  below `-40 °C` or above `50 °C`.
- Exact absolute-zero inputs are rejected after dew-point policy resolution.
- Representative cold and hot rows retain their temperatures and attempt both
  component solvers without false `Unbracketed` results.
- Invalid psychrometric or transport state is rejected before either solver.
- Ordinary-domain fixtures retain their existing values and tolerances.
- Focused local tests and the full package test suite pass.

## Non-goals

Changing standalone psychrometric helpers, solver-tolerance policy,
irradiance closure, or root-search guardrails is outside this specification.
No external benchmark or dataset is required.
