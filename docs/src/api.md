# Public API

The public surface covers Liljegren outdoor WBGT, RCC estimated-WBGT models,
selected direct heat measures, and their supporting helpers and types.

## Wind-height preprocessing

```julia
wind_speed_at_height(speed_m_s, measurement_height_m;
                     reference_height_m=2.0,
                     policy=LiljegrenStabilityPowerLaw(), terrain=Rural(),
                     stability_class=nothing, daytime=nothing,
                     ghi_w_m2=nothing,
                     vertical_temperature_difference_c=nothing,
                     minimum_wind_speed_m_s=nothing)

diagnose_wind_speed_at_height(speed_m_s, measurement_height_m; ...)
```

The value API returns reference-height wind. The diagnostic form also reports
the supplied wind, selected stability class and exponent, pre-floor adjusted
wind, post-floor effective wind, and adjustment flags. `StabilityA` through
`StabilityF` can be supplied explicitly when classifier meteorology is absent.

`solar_zenith`, `solar_zenith_batch`, `saturation_vapour_pressure_hpa`,
`vapour_pressure`, and `relative_humidity_from_dewpoint` are also exported
helpers. See [Inputs and policies](@ref) for their units and timestamp rules.

## Secondary measures

```julia
wbgt_with_solar_load(natural_wet_bulb_c, globe_temperature_c,
                     dry_bulb_temperature_c)
wbgt_without_solar_load(natural_wet_bulb_c, globe_temperature_c)
heat_index_nws(air_temperature_c, relative_humidity_percent)
wet_bulb_temperature_stull(air_temperature_c, relative_humidity_percent)
humidex(air_temperature_c, dew_point_c)
```

These functions return promoted scalar values or `missing`. Use broadcasting
for arrays. Their exact sources, domains, and limitations are documented in
[Secondary heat measures](@ref).

## Scalar calls

```julia
liljegren_wbgt(air_temperature_c, dew_point_c, wind_speed_m_s,
                time, longitude_deg, latitude_deg;
                ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                partition=FixedDirectFraction(0.8), pressure_hpa=1010,
                wind_height_m=2.0,
                wind_height_policy=NoWindHeightAdjustment(),
                terrain=Rural(), stability_class=nothing,
                vertical_temperature_difference_c=nothing,
                config=LiljegrenConfig())

diagnose_liljegren(air_temperature_c, dew_point_c, wind_speed_m_s,
                   time, longitude_deg, latitude_deg;
                   ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                   partition=FixedDirectFraction(0.8), pressure_hpa=1010,
                   wind_height_m=2.0,
                   wind_height_policy=NoWindHeightAdjustment(),
                   terrain=Rural(), stability_class=nothing,
                   vertical_temperature_difference_c=nothing,
                   config=LiljegrenConfig())
```

`liljegren_wbgt` returns `WBGTResult`; `diagnose_liljegren` returns
`DiagnosticWBGTResult`. `globe_temperature` and
`natural_wet_bulb_temperature` expose the corresponding scalar components.

## Batch calls

```julia
liljegren_wbgt_batch(air, dew, wind, time, longitude, latitude;
                      ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                      partition=FixedDirectFraction(0.8), pressure_hpa=1010,
                      config=LiljegrenConfig(), threaded=false)

liljegren_wbgt!(wbgt_out, wet_out, globe_out, air, dew, wind, time,
                 longitude, latitude; ghi_w_m2=nothing, dni_w_m2=nothing,
                 dhi_w_m2=nothing, partition=FixedDirectFraction(0.8),
                 pressure_hpa=1010, config=LiljegrenConfig(), threaded=false)

diagnose_liljegren_batch(air, dew, wind, time, longitude, latitude;
                         ghi_w_m2=nothing, dni_w_m2=nothing, dhi_w_m2=nothing,
                         partition=FixedDirectFraction(0.8), pressure_hpa=1010,
                         config=LiljegrenConfig(), threaded=false)
```

Batch rows are ordinally aligned. Longitude, latitude, pressure, irradiance,
fixed direct fraction, wind height, terrain, stability class, and vertical
temperature difference may be shared scalars or row-aligned vectors as
documented in [Units and input policies](@ref).

## RCC estimated-WBGT calls

```julia
rccd167l_wbgt(air, relative_humidity, wind, time, longitude, latitude;
               ghi_w_m2, pressure_hpa=1010,
               partition=LiljegrenClearnessFraction())
rcc_nws_wbgt(air, relative_humidity, wind, time, longitude, latitude;
              ghi_w_m2, pressure_hpa=1010,
              partition=LiljegrenClearnessFraction())

rccd167l_wbgt_batch(air, relative_humidity, wind, time, longitude, latitude;
                     ghi_w_m2, pressure_hpa=1010, threaded=false)
rcc_nws_wbgt_batch(air, relative_humidity, wind, time, longitude, latitude;
                    ghi_w_m2, pressure_hpa=1010, threaded=false)
```

The corresponding `!` forms accept three output vectors first. Component APIs
cover NWS psychrometric wet bulb, RCC-NWS/RCCNL natural wet bulb, and
Dim228/Dim167L globe temperature. See [RCC estimated WBGT](@ref) for exact
contracts and the operational-NDFD scope boundary.

## Types

`WBGTResult` and `WBGTBatchResult` contain values shared by Liljegren and RCC
estimators. `SolverConfig` controls Liljegren root and residual acceptance;
`LiljegrenConfig` contains its physical and input-policy settings.
`DiagnosticWBGTResult`,
`DiagnosticWBGTBatchResult`, and `SolverDiagnostics` expose input and solver
state. `DewPointPolicy`, `InputStatus`, and `FailureReason` are explicit enums.
`RadiationPartitionPolicy`, `FixedDirectFraction`, and
`LiljegrenClearnessFraction` control underdetermined radiation splits.
`IrradianceDiagnostics` reports the resolved component state and provenance.
`WindHeightPolicy`, `WindTerrain`, and `PasquillStabilityClass` control wind
conversion. `WindHeightDiagnostics` reports its complete scalar trace;
`WindHeightDiagnosticsBatch` is the aligned structure-of-arrays form.

```@docs
WindHeightPolicy
NoWindHeightAdjustment
LiljegrenStabilityPowerLaw
WindTerrain
PasquillStabilityClass
WindHeightDiagnostics
WindHeightDiagnosticsBatch
wind_speed_at_height
diagnose_wind_speed_at_height
```
