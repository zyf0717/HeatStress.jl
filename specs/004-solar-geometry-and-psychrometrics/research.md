# Solar geometry and psychrometrics: research

## Sources and decisions

- Spencer, J. W. (1971), “Fourier series representation of the position of the
  sun,” *Search*, 2, 172. The declination and equation-of-time coefficients in
  `spec.md` are transcribed from this publication; no implementation is used as
  a formula source. The surviving corrected transcription identifies `0.000075`
  as a printing error; the corrected equation-of-time constant is `0.0000075`.
  The correction history is recorded by the
  [pvlib documentation](https://pvlib-python.readthedocs.io/en/latest/reference/generated/pvlib.solarposition.equation_of_time_spencer71.html),
  citing correspondence with Spencer; it is correction provenance, not the
  equation authority.
- Allen et al. (1998), FAO Irrigation and Drainage Paper 56, equation 11.
  Its `0.6108` kPa form is converted to `6.108` hPa without changing the
  temperature coefficients.
- `DateNoonSolarTime` is removed. There is no documented scientific or
  compatibility case for treating a date as noon, and UTC instants avoid that
  ambiguity.

The daily approximation intentionally uses integer UTC day-of-year terms. It
is therefore piecewise-continuous at UTC midnight, not globally continuous.
This is the documented Spencer model choice; a fractional-day series would be
a different formulation and is not silently substituted here.

## Independent validation

- `test/test_solar_geometry.jl` freezes 15 geometric zenith fixtures generated
  on 2026-07-24 with `pvlib` 0.15.2 `spa_python`, an implementation of the
  NREL Solar Position Algorithm (Reda & Andreas, 2008), at 0 m altitude and
  0 Pa pressure to disable refraction. The set covers signed nonzero
  longitudes, before/after solar noon, equinoxes, solstices, high latitudes,
  leap/common February--March transitions, and geometric-horizon crossings.
  It asserts the maximum absolute zenith error is at most 2 degrees.
- FAO-56 hand-checks: `e_s(0 °C) = 6.108 hPa` directly, and the equation gives
  `e_s(25 °C) = 31.6778 hPa`; both are tested. Coefficients are converted from
  exact rationals into the target type, and a 256-bit BigFloat case compares
  against an independently evaluated expression with those exact decimals.
