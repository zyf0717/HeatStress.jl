# Irradiance component inputs: research

## Sources

- Liljegren et al. (2008), DOI `10.1080/15459620802310770`, equations 13--14,
  supplies the clearness-index direct-fraction relation used by the original
  model.
- Kasten and Czeplak (1980), DOI `10.1016/0038-092X(80)90391-6`, supplies the
  selected very-simple clear-sky GHI relation. Sandia report SAND2012-2389
  documents and evaluates this model.
- Allen et al. (1998), FAO Irrigation and Drainage Paper 56, equation 23,
  supplies the inverse relative Earth--Sun distance correction.
- NREL SERI-QC defines the normalized three-component closure relation and a
  `0.03` clearness-index-space acceptance band. This specification combines
  that relative band with a documented 20 W/m² absolute floor for
  low-irradiance numerical and measurement stability.

## Decisions

- Direct fraction is direct-horizontal/GHI. DNI is projected before use.
- The fixed 0.8 default is an explicit downstream clear-sky assumption, not a
  universal Liljegren constant. Measured component pairs take precedence.
- The original implementation's 0.85 clearness bound stabilises only the
  empirical partition estimator. Mutating the physical GHI would discard
  valid measurements, including cloud-enhancement events, and is not adopted.
- A singleton DHI cannot uniquely determine GHI through the clearness relation.
  Under the clearness policy, singleton DNI/DHI therefore uses the clear-sky
  complementary horizontal component instead of an ambiguous inverse.
- No-input calls mean estimated clear-sky full sun, not shade. Shade is
  represented explicitly by zero GHI or zero components.
