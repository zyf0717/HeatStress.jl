# Shared physical constants and fixed Liljegren-instrument parameters.
#
# Sources are inventoried in `docs/src/provenance.md`.  The values below are
# deliberately model constants, rather than periodically updated CODATA values:
# the Liljegren calculation must retain its documented numerical convention.

# Exact Celsius-to-Kelvin conversion (SI Brochure; K = °C + 273.15).
const KELVIN_OFFSET = 273.15

# Liljegren et al. (2008), Table 1; W m^-2 K^-4.
# Retained as published for model compatibility; see provenance for the CODATA
# comparison value.
const STEFAN_BOLTZMANN = 5.6696e-8

# Liljegren et al. (2008), Table 1 and supporting heat/mass-transfer equations.
const SPECIFIC_HEAT_DRY_AIR = 1003.5 # J kg^-1 K^-1
const MOLAR_MASS_DRY_AIR = 28.97 # kg kmol^-1
const MOLAR_MASS_WATER = 18.015 # kg kmol^-1
const UNIVERSAL_GAS_CONSTANT = 8314.34 # J kmol^-1 K^-1
const GAS_CONSTANT_DRY_AIR = UNIVERSAL_GAS_CONSTANT / MOLAR_MASS_DRY_AIR # J kg^-1 K^-1

# Package API fallback; pressure is an explicit meteorological input in the
# canonical Liljegren model, not a model-defined default.
const DEFAULT_PRESSURE_HPA = 1010.0
const DEFAULT_SURFACE_ALBEDO = 0.45
const DEFAULT_GLOBE_DIAMETER_M = 0.0508
# Canonical Liljegren computational wind floor, configurable as package policy.
const DEFAULT_MINIMUM_WIND_SPEED_M_S = 0.13
const GLOBE_EMISSIVITY = 0.95
const GLOBE_ALBEDO = 0.05
const SURFACE_EMISSIVITY = 0.999
const WICK_EMISSIVITY = 0.95
const WICK_ALBEDO = 0.4
const WICK_DIAMETER_M = 0.007
const WICK_LENGTH_M = 0.0254

# Original numerical policy: direct-beam terms expressed from horizontal
# irradiance are discarded below 1 degree solar elevation.  The `1/cos(θ)`
# and `tan(θ)` transformations are otherwise unbounded at the horizon while
# the package has no direct-normal irradiance input to constrain them.  Diffuse
# forcing remains active.  This is not a physical night-time threshold.
const MINIMUM_DIRECT_SOLAR_ELEVATION_RAD = π / 180
