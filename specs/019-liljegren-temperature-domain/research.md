# Liljegren temperature-domain correction: research

## Removed policy

The `[-40, 50] °C` high-level Liljegren gate was an original package policy.
It was inherited from the standalone FAO-56 psychrometric-helper contract, not
established by Liljegren et al. as a model validity interval. FAO-56 equation
11 supplies the saturation-vapour-pressure relation and Celsius units but does
not state that exact interval as the equation's domain.

Removing the gate provides calculation support only. Dedicated validation is
still required before making scientific-accuracy claims for extreme
conditions.

## Adjacent-gate audit

- Standalone `saturation_vapour_pressure_hpa` and
  `relative_humidity_from_dewpoint` retain their released `[-40, 50] °C`
  contract. The exact interval was not located in FAO-56 and should be handled
  by a separate API specification using mathematical-domain, finite-result and
  extrapolation rules.
- `residual_tolerance_k <= 0.01 K` remains an original conservative package
  acceptance policy. This correction does not change it.
- Irradiance closure remains unchanged. SERI-QC supplies the normalized
  closure concept and relative band; the `20 W/m²` absolute floor is explicitly
  a package reconciliation policy.
- The natural-wet-bulb `±100 K` and globe `±200 K` search limits remain
  original numerical termination guardrails. Representative new cold and hot
  tests verify that they do not cause false `Unbracketed` classifications.

## Source

- Allen, Pereira, Raes and Smith (1998), FAO Irrigation and Drainage Paper 56,
  Chapter 3, equation 11:
  <https://www.fao.org/4/X0490E/x0490e07.htm>.
