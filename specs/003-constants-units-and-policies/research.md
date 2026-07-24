# Constants, units and policies: research

## Source inventory

| Item | Selected source and location | Value / units | Decision |
| --- | --- | --- | --- |
| Liljegren model and sensor constants | Liljegren et al. (2008), Table 1 and sensor description | Values in `src/constants.jl` | Preserve the published numerical convention. |
| Globe/wick geometry and optics | Hall et al. (2022), §2.3.1–2.3.2, explicitly attributing values to Liljegren et al. | globe 0.0508 m, wick 0.007 m × 0.0254 m, ε/α values | Independent corroboration; no software source used. |
| Dry-air heat capacity and molar masses | Hall et al. (2022), §2.3.1 | 1003.5 J kg⁻¹ K⁻¹, 28.97 and 18.015 kg kmol⁻¹ | Retain model values. |
| SI conversion and modern reference comparison | NIST SP 250-39 (2009), Appendix A; NIST CODATA 2022 | 273.15 K offset; modern gas and Stefan–Boltzmann references | Model constants take precedence where they differ. |
| Surface albedo and wind floor | Kong et al. (2025), model-description text; Choi et al. (2022), methods | 0.45; original 0.13 m s⁻¹ | Compatibility values exposed in configuration. |
| Pressure and direct fraction defaults | v0.1 public API policy | 1010 hPa; 0.8 | Not physical invariants; callers may override. |

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
physics. The minimum wind floor is deferred to component physics so diagnostics
retain the supplied non-negative wind.
