"""
    humidex(air_temperature_c, dew_point_c)

Return humidex using the standard Environment and Climate Change Canada
dew-point formulation. Air temperature and dew point are degrees Celsius;
humidex is a dimensionless index customarily expressed on a Celsius-like
scale.

Both inputs must be finite and above absolute zero, and dew point must not
exceed air temperature. ECCC's thresholds for displaying hourly humidex are
presentation rules and are not imposed by this formula. A `missing` input
returns `missing`.
"""
@inline function humidex(air_temperature_c::_MaybeReal, dew_point_c::_MaybeReal)
    any(ismissing, (air_temperature_c, dew_point_c)) && return missing
    temperature, dew_point = promote(float(air_temperature_c), float(dew_point_c))
    _require_finite(temperature, "air_temperature_c")
    _require_finite(dew_point, "dew_point_c")
    T = typeof(temperature)
    absolute_zero_c = -convert(T, 5463 // 20)
    temperature > absolute_zero_c ||
        throw(DomainError(temperature, "air_temperature_c must be above absolute zero"))
    dew_point > absolute_zero_c ||
        throw(DomainError(dew_point, "dew_point_c must be above absolute zero"))
    dew_point <= temperature ||
        throw(DomainError(dew_point, "dew_point_c must not exceed air_temperature_c"))

    kelvin_offset = convert(T, 5463 // 20)
    dew_point_k = dew_point + kelvin_offset
    vapour_pressure_hpa = convert(T, 611 // 100) * exp(
        convert(T, 5417753 // 1000) *
        (inv(kelvin_offset) - inv(dew_point_k)),
    )
    return temperature +
           convert(T, 1111 // 2000) * (vapour_pressure_hpa - convert(T, 10))
end
