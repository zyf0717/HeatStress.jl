@inline function _globe_balance(
    prepared::_PreparedMeteorology{T},
    atmospheric_emissivity::T,
    effective_wind_speed_m_s::T,
    config::LiljegrenConfig{T},
) where {T<:AbstractFloat}
    return GlobeBalance(
        prepared.air_temperature_k,
        prepared.pressure_hpa,
        effective_wind_speed_m_s,
        _globe_longwave_term(
            prepared.air_temperature_k,
            atmospheric_emissivity,
        ),
        _globe_solar_term(
            prepared.solar_radiation_w_m2,
            prepared.direct_fraction,
            prepared.solar_zenith_rad,
            config.surface_albedo,
            convert(T, GLOBE_ALBEDO),
            convert(T, GLOBE_EMISSIVITY),
        ),
        config.globe_diameter_m,
        convert(T, GLOBE_EMISSIVITY),
    )
end

@inline function _wet_bulb_balance(
    prepared::_PreparedMeteorology{T},
    vapour_pressure_hpa::T,
    atmospheric_emissivity::T,
    effective_wind_speed_m_s::T,
    config::LiljegrenConfig{T},
) where {T<:AbstractFloat}
    return WetBulbBalance(
        prepared.air_temperature_k,
        prepared.pressure_hpa,
        effective_wind_speed_m_s,
        vapour_pressure_hpa,
        _wet_bulb_longwave_term(
            prepared.air_temperature_k,
            atmospheric_emissivity,
            convert(T, WICK_EMISSIVITY),
        ),
        _wet_bulb_solar_term(
            prepared.solar_radiation_w_m2,
            prepared.direct_fraction,
            prepared.solar_zenith_rad,
            config.surface_albedo,
            convert(T, WICK_ALBEDO),
            convert(T, WICK_DIAMETER_M),
            convert(T, WICK_LENGTH_M),
        ),
        true,
        convert(T, WICK_DIAMETER_M),
        convert(T, WICK_EMISSIVITY),
    )
end
