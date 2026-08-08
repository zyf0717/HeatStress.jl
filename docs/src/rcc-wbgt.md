# RCC estimated WBGT

HeatStress provides two first-class estimators from RCC WP-25-001:

- `rccd167l_wbgt`: Dim167L globe temperature plus RCCNL natural wet bulb.
- `rcc_nws_wbgt`: the report's evaluated Dim228 globe plus RCC-NWS natural
  wet-bulb combination.

Both return `WBGTResult`; their aligned batches return `WBGTBatchResult`. They
are estimated-WBGT models from meteorological inputs, unlike
`wbgt_with_solar_load` and `wbgt_without_solar_load`, which combine measured or
otherwise supplied component temperatures.

```julia
using Dates, HeatStress

result = rccd167l_wbgt(
    32.0, 40.0, 2.0, DateTime(2025, 7, 1, 12), 0.0, 0.0;
    ghi_w_m2 = 800.0,
    pressure_hpa = 900.0,
)
```

Relative humidity is percent. GHI is mandatory: the RCC APIs do not substitute
HeatStress's clear-sky estimate. Wind is model-ready and is not height-adjusted
or stability-corrected internally. Use `wind_speed_at_height` explicitly when
its independently sourced contract fits the caller's data. If station pressure
is missing, the composed result retains the independently computable globe
temperature while natural wet bulb and WBGT remain missing.

The default `LiljegrenClearnessFraction()` follows the direct-beam partition
used for the WP-25-001 evaluation. `FixedDirectFraction(value)` is an explicit
alternative. Both Dimiceli globe variants apply the report's 1 m/s wind floor,
surface albedo 0.2, 87-degree day/night threshold, and historical fixed
constants. RCCNL requires strictly positive wind because equation 9 divides by
`u^0.15` and the source gives no RCCNL floor.

## Component functions

```julia
psychrometric_wet_bulb_nws(air_c, rh_percent; pressure_hpa=1010.0)
rcc_nws_natural_wet_bulb_temperature(air_c, rh_percent, wind_m_s, ghi_w_m2;
                                      pressure_hpa=1010.0)
rccnl_natural_wet_bulb_temperature(air_c, rh_percent, wind_m_s, ghi_w_m2;
                                    pressure_hpa=1010.0)
dim228_globe_temperature(air_c, rh_percent, wind_m_s, ghi_w_m2,
                         solar_zenith_deg, direct_fraction)
dim167l_globe_temperature(air_c, rh_percent, wind_m_s, ghi_w_m2,
                          solar_zenith_deg, direct_fraction)
```

These scalar components broadcast normally. The globe component boundary uses
geometric zenith in degrees and direct-horizontal/GHI fraction explicitly;
composed APIs calculate geometry and the selected partition.

## Aligned batches

```julia
batch = rccd167l_wbgt_batch(
    air, relative_humidity, wind, times, longitude, latitude;
    ghi_w_m2 = ghi,
    pressure_hpa = pressure,
)

rccd167l_wbgt!(wbgt_out, wet_out, globe_out,
    air, relative_humidity, wind, times, longitude, latitude;
    ghi_w_m2 = ghi,
    pressure_hpa = pressure,
)
```

Coordinates, GHI, pressure, and a fixed fraction may be shared scalars or
aligned vectors. Shapes, output storage, domains, and aliases are validated
before preallocated writes. `threaded=true` is intentionally unavailable in
v0.4.0: these non-iterative rows require workload profiling before adding a
threading policy.

## NWS scope boundary

`rcc_nws_wbgt` names the component combination documented and evaluated in
RCC WP-25-001 Table 5. It is not a bit-for-bit implementation of the current
NWS/NDFD forecast production chain. In particular, it excludes NDFD cloud-cover
solar estimation, direct-fraction capping, land-cover wind downscaling,
pressure reduction, gridded albedo, and forecast-grid processing.

Source fidelity and independent equation fixtures do not establish universal
observational accuracy. No estimator is presented as universally correct;
model selection remains an application decision.

```@docs
HeatStress.psychrometric_wet_bulb_nws
HeatStress.rcc_nws_natural_wet_bulb_temperature
HeatStress.rccnl_natural_wet_bulb_temperature
HeatStress.dim228_globe_temperature
HeatStress.dim167l_globe_temperature
HeatStress.rccd167l_wbgt
HeatStress.rcc_nws_wbgt
HeatStress.rccd167l_wbgt_batch
HeatStress.rccd167l_wbgt!
HeatStress.rcc_nws_wbgt_batch
HeatStress.rcc_nws_wbgt!
```
