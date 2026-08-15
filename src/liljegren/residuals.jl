# Pure residuals for the Liljegren globe and natural wet-bulb balances.

"""Precomputed globe terms; `longwave_term` and `solar_term` have units K^4."""
struct GlobeBalance{T<:AbstractFloat}
    air_temperature_k::T
    pressure_hpa::T
    effective_wind_m_s::T
    longwave_term::T
    solar_term::T
    globe_diameter_m::T
    globe_emissivity::T
end

"""Precomputed wick terms; longwave and solar terms have units W m^-2."""
struct WetBulbBalance{T<:AbstractFloat}
    air_temperature_k::T
    pressure_hpa::T
    effective_wind_m_s::T
    vapour_pressure_hpa::T
    longwave_term::T
    solar_term::T
    radiation_enabled::Bool
    wick_diameter_m::T
    wick_emissivity::T
end

"""Direct-beam geometry shared by globe and wick solar forcing.

Zenith is in radians. At and below the geometric horizon direct radiation is
physically absent. At zenith angles of 89.5 degrees or greater, direct
radiation is discarded as specified by Liljegren et al. (2008); diffuse forcing
remains active. The last tuple value distinguishes that clip from physical
night-time zeroing.
"""
@inline function _direct_solar_geometry(zenith_rad::T) where {T<:AbstractFloat}
    horizon_rad = convert(T, π / 2)
    zenith_rad >= horizon_rad && return (zero(T), zero(T), false, false)
    zenith_rad >= horizon_rad - convert(T, MINIMUM_DIRECT_SOLAR_ELEVATION_RAD) &&
        return (zero(T), zero(T), false, true)
    return (
        inv(convert(T, 2) * cos(zenith_rad)),
        tan(zenith_rad) / convert(T, π),
        true,
        false,
    )
end

@inline function _globe_longwave_term(
        air_temperature_k::T,
        atmospheric_emissivity::T,
    ) where {T<:AbstractFloat}
    return (atmospheric_emissivity + one(T)) * air_temperature_k^4 / convert(T, 2)
end

@inline function _globe_solar_term(
        solar_radiation_w_m2::T,
        direct_fraction::T,
        zenith_rad::T,
        surface_albedo::T,
        globe_albedo::T,
        globe_emissivity::T,
    ) where {T<:AbstractFloat}
    globe_projection, _, _, _ = _direct_solar_geometry(zenith_rad)
    forcing = one(T) - direct_fraction + direct_fraction * globe_projection + surface_albedo
    return solar_radiation_w_m2 * (one(T) - globe_albedo) * forcing /
           (convert(T, 2) * globe_emissivity * convert(T, STEFAN_BOLTZMANN))
end

@inline function _wet_bulb_longwave_term(
        air_temperature_k::T,
        atmospheric_emissivity::T,
        wick_emissivity::T,
    ) where {T<:AbstractFloat}
    return convert(T, STEFAN_BOLTZMANN) * wick_emissivity *
           (atmospheric_emissivity + one(T)) * air_temperature_k^4 / convert(T, 2)
end

@inline function _wet_bulb_solar_term(
        solar_radiation_w_m2::T,
        direct_fraction::T,
        zenith_rad::T,
        surface_albedo::T,
        wick_albedo::T,
        wick_diameter_m::T,
        wick_length_m::T,
    ) where {T<:AbstractFloat}
    _, wick_projection, _, _ = _direct_solar_geometry(zenith_rad)
    diffuse_geometry = one(T) + wick_diameter_m / (convert(T, 4) * wick_length_m)
    direct_geometry = wick_projection + wick_diameter_m / (convert(T, 4) * wick_length_m)
    forcing = (one(T) - direct_fraction) * diffuse_geometry +
              direct_fraction * direct_geometry + surface_albedo
    return solar_radiation_w_m2 * (one(T) - wick_albedo) * forcing
end

@inline function _globe_equilibrium_radicand_k4(
        globe_temperature_k::T,
        balance::GlobeBalance{T},
    ) where {T<:AbstractFloat}
    film_temperature_k = (globe_temperature_k + balance.air_temperature_k) / convert(T, 2)
    coefficient = _heat_transfer_sphere_air(
        film_temperature_k,
        balance.pressure_hpa,
        balance.effective_wind_m_s,
        balance.globe_diameter_m,
    )
    return (
        balance.longwave_term -
        coefficient * (globe_temperature_k - balance.air_temperature_k) /
        (balance.globe_emissivity * convert(T, STEFAN_BOLTZMANN)) +
        balance.solar_term
    )
end

@inline function _globe_equilibrium_k(globe_temperature_k::T, balance::GlobeBalance{T}) where {T<:AbstractFloat}
    radicand_k4 = _globe_equilibrium_radicand_k4(globe_temperature_k, balance)
    return radicand_k4 >= zero(T) ? radicand_k4^convert(T, 1 // 4) : oftype(radicand_k4, NaN)
end

"""Fourth-power globe energy residual in K^4; use this to locate a root."""
@inline function _globe_energy_residual_k4(
        globe_temperature_k::T,
        balance::GlobeBalance{T},
    ) where {T<:AbstractFloat}
    return globe_temperature_k^4 - _globe_equilibrium_radicand_k4(globe_temperature_k, balance)
end

"""Kelvin-scale globe fixed-point residual; use this for final acceptance."""
@inline function _globe_fixed_point_residual_k(
        globe_temperature_k::T,
        balance::GlobeBalance{T},
    ) where {T<:AbstractFloat}
    return globe_temperature_k - _globe_equilibrium_k(globe_temperature_k, balance)
end

"""Signed natural wet-bulb fixed-point heat-balance residual in K."""
@inline function _natural_wet_bulb_residual(
        wet_bulb_temperature_k::T,
        balance::WetBulbBalance{T},
    ) where {T<:AbstractFloat}
    wet_bulb_temperature_c = wet_bulb_temperature_k - convert(T, KELVIN_OFFSET)
    minimum_c = convert(T, BUCK_MINIMUM_TEMPERATURE_C)
    maximum_c = convert(T, BUCK_MAXIMUM_TEMPERATURE_C)
    isfinite(wet_bulb_temperature_c) && minimum_c <= wet_bulb_temperature_c <= maximum_c ||
        return T(NaN)

    film_temperature_k = (wet_bulb_temperature_k + balance.air_temperature_k) / convert(T, 2)
    density = _air_density(film_temperature_k, balance.pressure_hpa)
    viscosity = _air_viscosity(film_temperature_k)
    conductivity = _air_thermal_conductivity(film_temperature_k)
    diffusivity = _air_diffusivity(film_temperature_k, balance.pressure_hpa)
    mass_transfer_ratio = _diffusivity_coefficient_from_properties(
        density,
        viscosity,
        conductivity,
        diffusivity,
    )
    coefficient = _heat_transfer_cylinder_air(
        film_temperature_k,
        balance.effective_wind_m_s,
        balance.wick_diameter_m,
        density,
        viscosity,
    )
    saturated_pressure_hpa = _buck_saturation_vapour_pressure_hpa(
        wet_bulb_temperature_c,
        balance.pressure_hpa,
    )
    all(isfinite, (density, viscosity, conductivity, diffusivity,
                   mass_transfer_ratio, coefficient, saturated_pressure_hpa)) &&
        density > zero(T) && viscosity > zero(T) && conductivity > zero(T) &&
        diffusivity > zero(T) && mass_transfer_ratio > zero(T) && coefficient > zero(T) &&
        saturated_pressure_hpa < balance.pressure_hpa || return T(NaN)
    evaporation_cooling_k = _latent_heat_vaporization(film_temperature_k) /
                            convert(T, SPECIFIC_HEAT_DRY_AIR) *
                            mass_transfer_ratio *
                            (saturated_pressure_hpa - balance.vapour_pressure_hpa) /
                            (balance.pressure_hpa - saturated_pressure_hpa)
    radiative_flux = balance.radiation_enabled ?
                     balance.longwave_term + balance.solar_term -
                     convert(T, STEFAN_BOLTZMANN) * balance.wick_emissivity * wet_bulb_temperature_k^4 :
                     zero(T)
    equilibrium_temperature_k = balance.air_temperature_k - evaporation_cooling_k +
                                radiative_flux / coefficient
    return wet_bulb_temperature_k - equilibrium_temperature_k
end
