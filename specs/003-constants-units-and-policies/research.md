# Constants, units and policies: research

## Source inventory

| Item | Selected source and location | Value / units | Decision |
| --- | --- | --- | --- |
| Liljegren model and sensor constants | Liljegren et al. (2008), equations 2--17 and sensor description; the paper has no constants table | Values in `src/constants.jl` | Attribute each value to its actual equation, fit or supporting source. |
| Globe/wick geometry and optics | Hall et al. (2022), §2.3.1–2.3.2, explicitly attributing values to Liljegren et al. | globe 0.0508 m, wick 0.007 m × 0.0254 m, ε/α values | Independent corroboration; no software source used. |
| Dry-air heat capacity and molar masses | Hall et al. (2022), §2.3.1 | 1003.5 J kg⁻¹ K⁻¹, 28.97 and 18.015 kg kmol⁻¹ | Retain model values. |
| SI conversion and modern reference comparison | NIST SP 250-39 (2009), Appendix A; NIST CODATA 2022 | 273.15 K offset; modern gas and Stefan–Boltzmann references | Model constants take precedence where they differ. |
| Surface albedo and wind floor | Liljegren et al. (2008), p. 648 fitted-coefficient text and Figure 6 caption, p. 653 | 0.45; 0.13 m s⁻¹ | Albedo is fitted; wind default is the estimated 2 m sensor threshold. |
| Pressure fallback | v0.1 public API policy | 1010 hPa | Package fallback only; the published calculation takes observed pressure explicitly. |
| Buck domain | Buck (1981), liquid and supercooled-liquid ranges | -40 through 50 °C | No extrapolation in the Liljegren dependency. |

## Discrepancy record

`STEFAN_BOLTZMANN = 5.6696e-8` is the selected historical Liljegren-model
constant. Modern CODATA gives approximately `5.670374419e-8` W m⁻² K⁻⁴.
The historical value is retained to avoid silently changing the model. A
scientific fixture sensitivity comparison is required before any revision.

## Policy rationale

Negative wind and radiation are physically invalid as supplied measurements but
are recoverable acquisition artefacts. v0.1 normalizes each to zero and emits a
separate diagnostic flag; non-finite values remain invalid. This is an explicit
package boundary policy, covered by unit tests, not a claim about the underlying
physics. The minimum wind floor is applied after optional height conversion so
diagnostics retain the supplied, converted and physics-effective wind stages.
