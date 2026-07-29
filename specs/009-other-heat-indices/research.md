# Secondary heat measures: research

## Selected authorities

- OSHA Technical Manual, Section III, Chapter 4: measured WBGT equations with
  and without solar load.
- National Weather Service: operational heat-index procedure based on the
  Rothfusz regression, including the simple estimate and humidity adjustments.
- Stull, R. (2011), “Wet-Bulb Temperature from Relative Humidity and Air
  Temperature”, DOI `10.1175/JAMC-D-11-0143.1`, equation 1.
- Environment and Climate Change Canada climate glossary: standard humidex
  equation using air temperature and dew point.

## Decisions

- Use formulation-specific `heat_index_nws` and
  `wet_bulb_temperature_stull` names.
- Use explicit `wbgt_with_solar_load` and `wbgt_without_solar_load` names
  rather than a Boolean or environment policy.
- Keep formula-native inputs and reject invalid domains with `DomainError`.
- Treat NWS and ECCC reporting/applicability statements as documentation where
  the authority supplies no numeric mathematical boundary.
- Keep UTCI separate because its input and validation contracts are materially
  larger than the direct-formula slice.

## Known limitations

- Measured-component WBGT requires representative instrument component
  temperatures and does not replace site-specific measurement practice.
- NWS heat index omits wind, solar/radiant load and workload.
- Stull is an empirical standard-pressure approximation and the source gives
  only a qualitative cold/dry exclusion within its numeric rectangle.
- Humidex is not a physiological or occupational exposure limit.
