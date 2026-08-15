# Liljegren provenance conformance

## Objective

Align the Liljegren WBGT implementation with the equations and stated
assumptions in Liljegren et al. (2008), while retaining the package's public
interfaces, diagnostic model, bisection solver and selected solar-position
algorithm.

This unit supersedes incompatible Liljegren scientific claims in earlier
specifications. It does not change the standalone FAO-56 psychrometric helper
contract or the RCC models.

## Requirements

1. Liljegren actual and saturated vapour pressures shall use the
   pressure-enhanced Buck (1981) liquid-water equations:
   - supercooled liquid water for `-40 <= T < 0` degrees Celsius;
   - liquid water for `0 <= T <= 50` degrees Celsius;
   - no extrapolation outside those intervals.
2. After dew-point policy resolution, an out-of-range dew point shall produce
   row-level `InvalidDomain`, with both component solves unattempted.
3. The natural-wet-bulb root search shall be bounded to the Buck interval. A
   root that cannot be bracketed within it shall retain the existing
   `Unbracketed` component reason. Air temperature alone shall not be rejected
   solely because it lies outside the Buck interval.
4. Every temperature-dependent wick transport property shall be evaluated at
   `(Tair + Twick) / 2` for every residual evaluation.
5. Surface long-wave forcing shall implement the paper's effective assumption
   `epsilon_surface * T_surface^4 = T_air^4`, without a separate `0.999`
   multiplier.
6. Liljegren equation 13 shall use its uncapped clearness ratio and shall clamp
   only the resulting physical direct fraction to `[0, 1]`. Direct forcing
   shall be zero for solar zenith angles at or above `89.5` degrees.
7. The configurable `0.13 m/s` default minimum wind shall be applied after
   wind-height conversion and cited to Liljegren Figure 6, where it is the
   estimated two-metre sensor threshold.
8. Existing scientific fixtures shall be replaced in place from an independent
   high-precision generator. Their metadata and hashes shall identify the new
   equations and generator revision.
9. `Project.toml` and `CITATION.cff` shall declare candidate version `0.5.0`
   before the final validation run.

## Acceptance criteria

- Public Liljegren signatures, result structures and enum members are unchanged.
- Buck branch, endpoint, pressure-enhancement and rejection tests pass for
  `Float32`, `Float64` and `BigFloat` where supported.
- Scalar, batch, threaded, diagnostic and fixture paths agree.
- Focused tests, fixture reproducibility checks, documentation checks and the
  complete package test suite pass on the final candidate head.
- The final-head audit records any unresolved external CI/merge gate without
  claiming completion prematurely.
