# Pure scalar heat-transfer kernels for the Liljegren balances.  Temperatures
# are Kelvin, pressure is hPa, lengths are m, and coefficients are W m^-2 K^-1.

"""Dynamic viscosity of dry air in Pa s (Bird et al. 2006, eq. 1.4-14)."""
@inline function _air_viscosity(air_temperature_k::T) where {T<:AbstractFloat}
    reduced_temperature = air_temperature_k / oftype(air_temperature_k, 97)
    collision_integral =
        oftype(air_temperature_k, 1.16145) * reduced_temperature^oftype(air_temperature_k, -0.14874) +
        oftype(air_temperature_k, 0.52487) * exp(-oftype(air_temperature_k, 0.77320) * reduced_temperature) +
        oftype(air_temperature_k, 2.16178) * exp(-oftype(air_temperature_k, 2.43787) * reduced_temperature)
    return oftype(air_temperature_k, 2.6693e-6) *
           sqrt(oftype(air_temperature_k, MOLAR_MASS_DRY_AIR) * air_temperature_k) /
           (oftype(air_temperature_k, 3.617)^2 * collision_integral)
end

"""Thermal conductivity of air in W m^-1 K^-1 (Kannuluik and Carman 1951)."""
@inline function _air_thermal_conductivity(air_temperature_k::T) where {T<:AbstractFloat}
    temperature_c = air_temperature_k - oftype(air_temperature_k, KELVIN_OFFSET)
    return oftype(air_temperature_k, 5.75e-5) *
           (one(T) + oftype(air_temperature_k, 0.00317) * temperature_c -
            oftype(air_temperature_k, 0.0000021) * temperature_c^2) *
           oftype(air_temperature_k, 418.4)
end

"""Dry-air density in kg m^-3 from the ideal-gas law."""
@inline function _air_density(air_temperature_k::T, pressure_hpa::T) where {T<:AbstractFloat}
    return pressure_hpa * oftype(air_temperature_k, 100) *
           oftype(air_temperature_k, MOLAR_MASS_DRY_AIR) /
           (oftype(air_temperature_k, UNIVERSAL_GAS_CONSTANT) * air_temperature_k)
end

"""Water-vapour diffusivity in air in m^2 s^-1 (Bird et al. 2006, eq. 17.2-1)."""
@inline function _air_diffusivity(air_temperature_k::T, pressure_hpa::T) where {T<:AbstractFloat}
    critical_temperature_product = convert(T, 132.6 * 647.1)
    critical_pressure_product = convert(T, 217.7 * 37.36)
    reduced_temperature = air_temperature_k / sqrt(critical_temperature_product)
    molecular_mass_term = sqrt(
        inv(convert(T, MOLAR_MASS_DRY_AIR)) + inv(convert(T, MOLAR_MASS_WATER)),
    )
    return convert(T, 0.000364) * reduced_temperature^convert(T, 2.334) *
           critical_pressure_product^convert(T, 1 // 3) *
           critical_temperature_product^convert(T, 5 // 12) * molecular_mass_term /
           ((pressure_hpa / convert(T, 1013.25)) * convert(T, 10_000))
end

"""Dimensionless `(M_w/M_a) (Pr/Sc)^0.56` mass-transfer correction."""
@inline function _diffusivity_coefficient(
        air_temperature_k::T,
        pressure_hpa::T,
        air_density::T = _air_density(air_temperature_k, pressure_hpa),
        air_viscosity::T = _air_viscosity(air_temperature_k),
    ) where {T<:AbstractFloat}
    conductivity = _air_thermal_conductivity(air_temperature_k)
    prandtl = convert(T, SPECIFIC_HEAT_DRY_AIR) * air_viscosity / conductivity
    schmidt = air_viscosity / (air_density * _air_diffusivity(air_temperature_k, pressure_hpa))
    return convert(T, MOLAR_MASS_WATER / MOLAR_MASS_DRY_AIR) *
           (prandtl / schmidt)^convert(T, 0.56)
end

"""Atmospheric long-wave emissivity from vapour pressure in hPa (Oke 1987)."""
@inline function _atmospheric_emissivity(vapour_pressure_hpa::T) where {T<:AbstractFloat}
    return convert(T, 0.575) * vapour_pressure_hpa^convert(T, 1 // 7)
end

@inline function _heat_transfer_sphere_air(
        air_temperature_k::T,
        pressure_hpa::T,
        wind_speed_m_s::T,
        diameter_m::T,
    ) where {T<:AbstractFloat}
    density = _air_density(air_temperature_k, pressure_hpa)
    viscosity = _air_viscosity(air_temperature_k)
    conductivity = _air_thermal_conductivity(air_temperature_k)
    reynolds = density * wind_speed_m_s * diameter_m / viscosity
    prandtl = convert(T, SPECIFIC_HEAT_DRY_AIR) * viscosity / conductivity
    nusselt = convert(T, 2) + convert(T, 0.6) * sqrt(reynolds) * cbrt(prandtl)
    return nusselt * conductivity / diameter_m
end

@inline function _heat_transfer_cylinder_air(
        air_temperature_k::T,
        pressure_hpa::T,
        wind_speed_m_s::T,
        diameter_m::T,
    ) where {T<:AbstractFloat}
    # The forced-convection correlation returns zero at zero wind. Callers
    # constructing an irradiated wet-bulb balance must apply their configured
    # effective-wind floor before entering this kernel.
    density = _air_density(air_temperature_k, pressure_hpa)
    viscosity = _air_viscosity(air_temperature_k)
    return _heat_transfer_cylinder_air(
        air_temperature_k,
        wind_speed_m_s,
        diameter_m,
        density,
        viscosity,
    )
end

@inline function _heat_transfer_cylinder_air(
        air_temperature_k::T,
        wind_speed_m_s::T,
        diameter_m::T,
        air_density::T,
        air_viscosity::T,
    ) where {T<:AbstractFloat}
    conductivity = _air_thermal_conductivity(air_temperature_k)
    reynolds = air_density * wind_speed_m_s * diameter_m / air_viscosity
    prandtl = convert(T, SPECIFIC_HEAT_DRY_AIR) * air_viscosity / conductivity
    nusselt = convert(T, 0.281) * reynolds^convert(T, 0.6) * prandtl^convert(T, 0.44)
    return nusselt * conductivity / diameter_m
end

"""Latent heat of vaporization in J kg^-1 (Oke 1987, table A3.1 fit)."""
@inline function _latent_heat_vaporization(air_temperature_k::T) where {T<:AbstractFloat}
    return convert(T, 1e6) * (
        convert(T, 1.748942) + convert(T, 0.01405870) * air_temperature_k -
        convert(T, 6.376351e-5) * air_temperature_k^2 +
        convert(T, 8.187135e-8) * air_temperature_k^3
    )
end
