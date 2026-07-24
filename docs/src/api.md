# Public API

The public surface currently covers Liljegren outdoor WBGT and its supporting
configuration, status, result, and diagnostic types.

`solar_zenith`, `solar_zenith_batch`, `saturation_vapour_pressure_hpa`,
`vapour_pressure`, and `relative_humidity_from_dewpoint` are also exported
helpers. See [Inputs and policies](@ref) for their units and timestamp rules.

## Scalar calls

```julia
liljegren_wbgt(air_temperature_c, dew_point_c, wind_speed_m_s,
                solar_radiation_w_m2, time, longitude_deg, latitude_deg;
                pressure_hpa=1010, direct_fraction, config=LiljegrenConfig())

diagnose_liljegren(air_temperature_c, dew_point_c, wind_speed_m_s,
                   solar_radiation_w_m2, time, longitude_deg, latitude_deg;
                   pressure_hpa=1010, direct_fraction, config=LiljegrenConfig())
```

`liljegren_wbgt` returns `WBGTResult`; `diagnose_liljegren` returns
`DiagnosticWBGTResult`. `globe_temperature` and
`natural_wet_bulb_temperature` expose the corresponding scalar components.

## Batch calls

```julia
liljegren_wbgt_batch(air, dew, wind, radiation, time, longitude, latitude;
                      pressure_hpa=1010, direct_fraction,
                      config=LiljegrenConfig(), threaded=false)

liljegren_wbgt!(wbgt_out, wet_out, globe_out, air, dew, wind, radiation,
                 time, longitude, latitude; pressure_hpa=1010,
                 direct_fraction, config=LiljegrenConfig(), threaded=false)

diagnose_liljegren_batch(air, dew, wind, radiation, time, longitude, latitude;
                         pressure_hpa=1010, direct_fraction,
                         config=LiljegrenConfig(), threaded=false)
```

Batch rows are ordinally aligned. Longitude, latitude, pressure, and direct
fraction may be shared scalars or row-aligned vectors as documented in
[Units and input policies](@ref).

## Types

`SolverConfig` controls root and residual acceptance. `LiljegrenConfig`
contains physical and input-policy settings. `WBGTResult` and
`WBGTBatchResult` contain values; `DiagnosticWBGTResult`,
`DiagnosticWBGTBatchResult`, and `SolverDiagnostics` expose input and solver
state. `DewPointPolicy`, `InputStatus`, and `FailureReason` are explicit enums.
