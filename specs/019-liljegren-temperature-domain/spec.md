# Liljegren temperature-domain correction (superseded)

## Historical result

Version 0.3.2 removed an unsourced high-level range check and allowed any
finite Kelvin-positive air/dew-point pair to reach derived-state validation.
That behavior was correct relative to the then-selected FAO extrapolation, but
the dependency audit in spec 022 found that Liljegren explicitly selects Buck
(1981).

## Current authority

Spec 022 supersedes this unit for current behavior:

- resolved dew point must be in `[-40, 50] °C` because it is an input to the
  bounded Buck liquid/supercooled-liquid equations;
- wet-bulb candidates are searched only in the same interval;
- air temperature itself has no independent Buck-range gate;
- an out-of-range dew point is `InvalidDomain`, while a root unavailable in
  the supported interval is component-level `Unbracketed`.

The standalone public FAO-56 helpers retain their spec-004 contract. This file
does not authorize extrapolating Buck or restoring the pre-v0.3.2 blanket air
temperature gate.
