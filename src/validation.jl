# Prepared scalar meteorology in the package's internal numeric units.
struct _PreparedMeteorology{T<:AbstractFloat}
    air_temperature_c::T
    dew_point_c::T
    air_temperature_k::T
    dew_point_k::T
    wind_speed_m_s::T
    solar_radiation_w_m2::T
    solar_zenith_rad::T
    pressure_hpa::T
    direct_fraction::T
    dew_point_adjusted::Bool
    wind_speed_clamped::Bool
    solar_radiation_clamped::Bool
    solar_geometry_mismatch::Bool
end

# Input-preparation failure represented without a numerical payload.
struct _InputPreparationFailure
    status::InputStatus
end

function _require_finite_in_range(value::T, lower::T, upper::T, name::Symbol) where {T<:AbstractFloat}
    isfinite(value) && lower <= value <= upper ||
        throw(ArgumentError("$name must be finite and in [$lower, $upper]"))
    return value
end

# Validate a longitude in degrees and return it unchanged.
function _validate_longitude_deg(longitude_deg::Real)
    value = float(longitude_deg)
    return _require_finite_in_range(value, typeof(value)(-180), typeof(value)(180), :longitude_deg)
end

# Validate a latitude in degrees and return it unchanged.
function _validate_latitude_deg(latitude_deg::Real)
    value = float(latitude_deg)
    return _require_finite_in_range(value, typeof(value)(-90), typeof(value)(90), :latitude_deg)
end

# Validate pressure in hPa; `missing` is allowed only at a batch boundary.
function _validate_pressure_hpa(pressure_hpa::Union{Missing,Real}; allow_missing::Bool = false)
    if ismissing(pressure_hpa)
        allow_missing && return missing
        throw(ArgumentError("pressure_hpa must not be missing"))
    end
    value = float(pressure_hpa)
    return _require_finite_positive(value, :pressure_hpa)
end

# Validate the direct fraction, expressed as direct / total radiation.
function _validate_direct_fraction(direct_fraction::Real)
    value = float(direct_fraction)
    return _require_finite_in_range(value, zero(value), one(value), :direct_fraction)
end

# Return physics-effective wind after applying the configured component floor.
function _effective_wind_speed_m_s(
    wind_speed_m_s::T,
    minimum_wind_speed_m_s::T,
) where {T<:AbstractFloat}
    return max(wind_speed_m_s, minimum_wind_speed_m_s)
end

# Normalize one meteorological observation before component physics. Temperatures
# are Celsius at this boundary; pressure is hPa, wind is m/s, radiation is W/m²,
# coordinates are degrees, and `solar_zenith_rad` is radians. The caller supplies
# the zenith calculated by the solar-geometry kernel so this policy layer remains
# independent of a specific solar-position equation.
function _normalize_meteorology(
    air_temperature_c::Union{Missing,Real},
    dew_point_c::Union{Missing,Real},
    wind_speed_m_s::Union{Missing,Real},
    solar_radiation_w_m2::Union{Missing,Real},
    time,
    longitude_deg::Real,
    latitude_deg::Real;
    pressure_hpa::Union{Missing,Real} = DEFAULT_PRESSURE_HPA,
    direct_fraction::Union{Missing,Real} = DEFAULT_DIRECT_FRACTION,
    solar_zenith_rad::Union{Missing,Real} = missing,
    config::LiljegrenConfig = LiljegrenConfig(),
)
    _validate_longitude_deg(longitude_deg)
    _validate_latitude_deg(latitude_deg)
    _validate_pressure_hpa(pressure_hpa; allow_missing = true)
    ismissing(direct_fraction) && return _InputPreparationFailure(MissingMeteorology)
    _validate_direct_fraction(direct_fraction)

    if ismissing(air_temperature_c) || ismissing(dew_point_c) || ismissing(wind_speed_m_s) ||
       ismissing(solar_radiation_w_m2) || ismissing(pressure_hpa)
        return _InputPreparationFailure(MissingMeteorology)
    end
    ismissing(time) && return _InputPreparationFailure(MissingTime)
    ismissing(solar_zenith_rad) && return _InputPreparationFailure(InvalidDomain)

    float_type = _common_float_type(
        air_temperature_c,
        dew_point_c,
        wind_speed_m_s,
        solar_radiation_w_m2,
        pressure_hpa,
        direct_fraction,
        solar_zenith_rad,
        config.dew_point_tolerance_c,
    )
    air = convert(float_type, air_temperature_c)
    dew = convert(float_type, dew_point_c)
    wind = convert(float_type, wind_speed_m_s)
    radiation = convert(float_type, solar_radiation_w_m2)
    pressure = convert(float_type, pressure_hpa)
    fraction = convert(float_type, direct_fraction)
    zenith = convert(float_type, solar_zenith_rad)

    all(isfinite, (air, dew, wind, radiation, pressure, fraction, zenith)) ||
        return _InputPreparationFailure(InvalidDomain)
    pressure > zero(float_type) || return _InputPreparationFailure(InvalidDomain)
    zero(float_type) <= fraction <= one(float_type) || return _InputPreparationFailure(InvalidDomain)

    resolution = _resolve_dew_point(
        air,
        dew,
        config.dew_point_policy,
        convert(float_type, config.dew_point_tolerance_c),
    )
    resolution.status === InputAccepted || return _InputPreparationFailure(resolution.status)

    wind_clamped = wind < zero(float_type)
    radiation_clamped = radiation < zero(float_type)
    wind = max(wind, zero(float_type))
    supplied_positive_radiation = radiation > zero(float_type)
    radiation = max(radiation, zero(float_type))
    below_horizon = cos(zenith) <= zero(float_type)
    mismatch = supplied_positive_radiation && below_horizon
    below_horizon && (radiation = zero(float_type))

    return _PreparedMeteorology(
        resolution.air_temperature_c,
        resolution.dew_point_c,
        resolution.air_temperature_c + float_type(KELVIN_OFFSET),
        resolution.dew_point_c + float_type(KELVIN_OFFSET),
        wind,
        radiation,
        zenith,
        pressure,
        fraction,
        resolution.adjusted,
        wind_clamped,
        radiation_clamped,
        mismatch,
    )
end

# Require aligned batch inputs before allocating or mutating result storage.
function _validate_batch_lengths(inputs::AbstractVector...)
    isempty(inputs) && return nothing
    reference_axes = axes(first(inputs))
    all(input -> axes(input) == reference_axes, inputs) ||
        throw(ArgumentError("batch input vectors must have identical axes"))
    return nothing
end
