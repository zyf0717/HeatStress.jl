# Solar geometry and psychrometrics: research

## Sources and decisions

- Spencer, J. W. (1971), “Fourier series representation of the position of the
  sun,” *Search*, 2, 172. The declination and equation-of-time coefficients in
  `spec.md` are transcribed from this publication; no implementation is used as
  a formula source.
- Allen et al. (1998), FAO Irrigation and Drainage Paper 56, equation 11.
  Its `0.6108` kPa form is converted to `6.108` hPa without changing the
  temperature coefficients.
- `DateNoonSolarTime` is removed. There is no documented scientific or
  compatibility case for treating a date as noon, and UTC instants avoid that
  ambiguity.

## Independent validation

- The two low-latitude test fixtures in `test/test_solar_geometry.jl` were
  checked on 2026-07-24 against the NOAA Solar Position Calculator
  (<https://gml.noaa.gov/grad/solcalc/azel.html>), which uses Meeus-based
  equations rather than Spencer's approximation. Tests allow the selected
  2-degree zenith tolerance. The NOAA calculator notes lower accuracy above
  72 degrees latitude; polar-adjacent tests therefore assert geometric
  below-horizon behavior rather than a high-accuracy numeric fixture.
- FAO-56 hand-checks: `e_s(0 °C) = 6.108 hPa` directly, and the equation gives
  `e_s(25 °C) = 31.6778 hPa`; both are tested. BigFloat preserves its input
  precision in the scalar saturation function.
