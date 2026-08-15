# Liljegren temperature-domain correction: supersession record

The original finding remains valid: `[-40, 50] °C` was not established as a
general validity interval by FAO-56, so a blanket high-level air/dew-point gate
was unsupported.

Spec 022 subsequently located the actual Liljegren dependency. Liljegren et
al. (2008), p. 647, names Buck (1981) for saturation vapour pressure. Buck's
selected liquid and supercooled-liquid equations have stated ranges covering
`[-40, 50] °C`. The correct boundary is therefore dependency-specific:

- enforce it where Buck is evaluated (resolved dew point and wet-bulb
  candidate);
- do not infer a matching air-temperature restriction;
- do not extrapolate the equations.

The prior ±100 K wet-bulb search is likewise superseded by the absolute Buck
interval. The ±200 K globe guardrail remains a package numerical policy.
