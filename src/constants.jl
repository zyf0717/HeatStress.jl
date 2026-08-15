# Shared physical constants and fixed Liljegren-instrument parameters.
#
# Sources are inventoried in `docs/src/provenance.md`.  The values below are
# deliberately model constants, rather than periodically updated CODATA values:
# the Liljegren calculation must retain its documented numerical convention.

# Exact Celsius-to-Kelvin conversion (SI Brochure; K = °C + 273.15).
const KELVIN_OFFSET = 273.15

# Model-compatible Stefan--Boltzmann value; W m^-2 K^-4. Liljegren et al.
# (2008), eqs. 11, 12, 15 and 17, defines its use but does not tabulate a
# numerical value. See the supporting-source inventory in the provenance docs.
const STEFAN_BOLTZMANN = 5.6696e-8

# Supporting heat/mass-transfer constants; Liljegren et al. (2008), eqs. 2--10.
const SPECIFIC_HEAT_DRY_AIR = 1003.5 # J kg^-1 K^-1
const MOLAR_MASS_DRY_AIR = 28.97 # kg kmol^-1
const MOLAR_MASS_WATER = 18.015 # kg kmol^-1
const UNIVERSAL_GAS_CONSTANT = 8314.34 # J kmol^-1 K^-1
const GAS_CONSTANT_DRY_AIR = UNIVERSAL_GAS_CONSTANT / MOLAR_MASS_DRY_AIR # J kg^-1 K^-1

# Package API fallback; pressure is an explicit meteorological input in the
# published Liljegren calculation, not a model-defined default.
const DEFAULT_PRESSURE_HPA = 1010.0
const DEFAULT_SURFACE_ALBEDO = 0.45
const DEFAULT_GLOBE_DIAMETER_M = 0.0508
# Liljegren et al. (2008), Figure 6 caption: estimated 2 m sensor threshold.
const DEFAULT_MINIMUM_WIND_SPEED_M_S = 0.13
const GLOBE_EMISSIVITY = 0.95
const GLOBE_ALBEDO = 0.05
const WICK_EMISSIVITY = 0.95
const WICK_ALBEDO = 0.4
const WICK_DIAMETER_M = 0.007
const WICK_LENGTH_M = 0.0254

# Liljegren et al. (2008), eqs. 13--14 and accompanying text: direct-beam
# forcing is zero at zenith angles greater than or equal to 89.5 degrees.
const MINIMUM_DIRECT_SOLAR_ELEVATION_RAD = π / 360

# Buck (1981) stated ranges used by the private Liljegren psychrometric kernel.
const BUCK_MINIMUM_TEMPERATURE_C = -40.0
const BUCK_MAXIMUM_TEMPERATURE_C = 50.0

# Kasten and Czeplak (1980) very-simple clear-sky GHI model, W m^-2.
const KASTEN_CZEPLAK_GHI_SLOPE_W_M2 = 910.0
const KASTEN_CZEPLAK_GHI_INTERCEPT_W_M2 = 30.0

# Liljegren et al. (2008), eqs. 13--14; the Earth--Sun distance calculation is
# a selected supporting algorithm rather than a literal paper transcription.
const LILJEGREN_SOLAR_CONSTANT_W_M2 = 1367.0
const DEFAULT_IRRADIANCE_CLOSURE_ATOL_W_M2 = 20.0
const DEFAULT_IRRADIANCE_CLOSURE_KT_TOLERANCE = 0.03
