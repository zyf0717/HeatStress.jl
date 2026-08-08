# RCC WBGT estimators

## Purpose

Add the RCC WP-25-001 `RCCD167L` estimator and the report's evaluated
`Dim228 + RCC-NWS` combination as explicit peers of the Liljegren model for
HeatStress v0.4.0.

## Requirements

- Export named scalar component and composed-model functions; do not add a
  model hierarchy or method-selecting dispatcher.
- Use relative humidity and pressure as the NWS psychrometric procedure's
  native humidity contract.
- Require measured or caller-modelled GHI. Do not synthesize clear-sky GHI.
- Use the existing geometric `solar_zenith` calculation and the Liljegren
  clearness-fraction partition by default, as used in WP-25-001.
- Consume model-ready wind without implicit height or stability conversion.
- Implement the Appendix B NWS psychrometric procedure with its published
  coefficients and exactly five Newton updates.
- Implement RCC-NWS natural wet bulb from equation 8 and RCCNL from equation
  9. RCCNL requires strictly positive wind because the source specifies no
  zero-wind floor for its denominator.
- Implement Dim228 from equations 3 and 4's predecessor heat-gain expression,
  and Dim167L from equations 3 and 4. Both use the report's 1 m/s Dimiceli
  wind floor, 87-degree day/night boundary, and fixed source constants.
- Reuse `WBGTResult` and `WBGTBatchResult` without field or behavior changes.
- Provide aligned allocating and preallocated batches with scalar expansion
  for location, GHI, pressure, and fixed direct fraction. Serial execution is
  required; `threaded=true` is accepted only if parity is retained.
- Preserve all released Liljegren signatures, defaults, policies and values.

## Acceptance criteria

- Every RCC equation, coefficient and policy is traceable in
  `validation/sources.toml`.
- Independent fixtures cover the five components and both compositions.
- Scalar, allocating-batch and preallocated results agree on every fixture.
- Invalid finite domains are rejected, while `missing` scientific inputs
  propagate without warnings or kernel network access.
- Float32 and Float64 promotion, component broadcasting, day/night boundary,
  radiation extremes, shape checks and alias rejection are tested.
- Documentation distinguishes RCCD167L, the RCC-evaluated NWS combination,
  Liljegren, and measured-component WBGT.
- Focused tests, full `Pkg.test()`, and the repository quality path pass.

## Non-goals

Exact reproduction of NWS/NDFD cloud-cover, solar-flux, roughness, wind-height,
pressure-reduction or forecast-grid preprocessing is excluded. No generic
model abstraction, configurable RCC coefficient family, unrelated WBGT model,
GPU implementation, observational-statistics oracle, release tag or registry
action is in scope.
