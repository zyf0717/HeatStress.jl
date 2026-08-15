# Research findings

## Primary paper

Liljegren, Carhart, Lawday, Tschopp and Sharp (2008), *Modeling the Wet Bulb
Globe Temperature Using Standard Meteorological Measurements*, DOI
`10.1080/15459620802310770`:

- p. 647 states that saturation vapour pressure is calculated using Buck
  (1981), and equations 10--11 define the wick heat and mass transfer.
- p. 648, equations 12--14, defines the surface long-wave approximation,
  direct/diffuse partition, fitted wick/surface coefficients and the 89.5
  degree solar-zenith treatment.
- p. 648 states that all properties are evaluated before each iteration at the
  average of wick and air temperatures.
- p. 649, equations 15--17, applies the same effective surface-radiation
  approximation to the globe.
- p. 653, Figure 6 caption, states that estimated two-metre wind is floored at
  `0.13 m/s`, the wind-sensor threshold. The paper does not present this as a
  universal meteorological minimum.

The paper contains no constants table; earlier `Table 1` locators for physical
constants were erroneous.

## Sensitivity against `main` at `a772ebe`

Values below use identical Float64 public calls and fixed fraction `0.7`
unless stated otherwise. Component columns are `(Tg, Tnwb, WBGT)` in degrees
Celsius.

| Case | Previous | Corrected | Delta / disposition |
| --- | --- | --- | --- |
| ordinary day, 30/20 °C, 1 m/s, 800 W/m² | `(47.57975, 25.81092, 30.58359)` | `(47.59398, 25.79141, 30.57278)` | `(+0.01422, -0.01951, -0.01081)` |
| zero supplied wind, otherwise ordinary | `(59.88435, 31.29417, 36.88279)` | `(59.90737, 31.26964, 36.87022)` | `(+0.02302, -0.02454, -0.01257)` |
| saturated 30 °C day | `(48.34689, 32.21330, 35.21869)` | `(48.36221, 32.20652, 35.21701)` | `(+0.01532, -0.00678, -0.00168)` |
| dew point -40 °C | `(16.21251, 0.07150, 3.29255)` | `(16.23575, 0.05873, 3.28826)` | `(+0.02324, -0.01277, -0.00429)` |
| air/dew 60/50 °C, no solar | `(61.92361, 51.03485, 54.10912)` | globe `61.95198`; wick `Unbracketed` | WBGT now missing; old wick root required Buck extrapolation |
| air/dew 60/55 °C | `(79.40085, 56.25004, 61.25520)` | `InvalidDomain` | both components unattempted |
| 0.657° solar elevation, 600 W/m² | `(38.35443, 24.88386, 28.08959)` | globe `Unbracketed`; wick `49.73691` | sourced 0.5° cutoff activates direct geometry where the old 1° policy clipped it |
| equation-13 partition, GHI 2000 W/m² | fraction `0.9`; WBGT `37.01849` | fraction `0.81063`; WBGT `37.66479` | removed input/output caps; physical output clamp retained |

The stable v3 matrix now has 59 complete rows and five valid partial rows whose
wet-bulb roots are outside the bounded Buck interval. Those five rows retain
their accepted globe values and have missing WBGT.

## Buck domain decision

Buck (1981), Table 1, gives the `17.502 / 240.97` liquid-water curve on
`[-20, 50] °C` and the `17.966 / 247.15` supercooled-liquid curve on
`[-40, 0] °C`. The paper's recommended moist-air expression supplies the
pressure factor `1.0007 + 3.46e-6 P` for pressure in hPa. The
implementation selects the ordinary liquid-water curve from zero through 50
degrees Celsius and the supercooled-liquid curve below zero through -40
degrees Celsius. Each selected branch remains inside its published interval;
endpoints are inclusive and neither branch is extrapolated. The article's
broader `[-80, 50] °C` abstract range also includes an ice curve and is not a
license to extend either selected liquid-water curve.

The public API supplies dew point, so actual vapour pressure is evaluated at
dew point rather than reconstructing relative humidity through the standalone
FAO helper. Air temperature therefore is not itself a Buck-domain gate.

## Retained implementation choices

Safeguarded bisection replaces the paper's relaxation iteration but solves the
same balance and provides explicit failure diagnostics. The package's solar
position and Earth--Sun distance algorithms remain supporting numerical
choices. Neither is attributed to Liljegren as a literal transcription.

## Local performance evidence

The fixed-station public scalar benchmark used 10,000 ordinary rows, three
samples, Julia 1.10.11, one thread and the same `goldmont` host. Median runtime
changed from `0.041607287 s` on `main` at `a772ebe` to `0.059910169 s` in this
working tree (`+43.99%`). Both runs allocated `330002` objects and `15840048`
bytes. The runtime increase is the measured cost of reevaluating wick
transport properties at every candidate-film temperature; it is disclosed,
not treated as scientific acceptance evidence.
