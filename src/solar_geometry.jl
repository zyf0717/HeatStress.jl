"""
    solar_zenith(time, longitude_deg, latitude_deg) -> Float64

Return the geometric solar zenith angle from Spencer's daily approximation in
degrees for a UTC `DateTime` or `ZonedDateTime` instant. Longitudes are
positive east of Greenwich and latitudes are positive north. A `DateTime` is
interpreted as UTC.

The calculation uses the Spencer (1971) Fourier series for solar declination
and equation of time. It returns the geometric angle without refraction or
horizon masking: values greater than 90 degrees are below the horizon.
"""
function solar_zenith(
        time::Union{DateTime,ZonedDateTime},
        longitude_deg::Real,
        latitude_deg::Real,
    )::Float64
    longitude = _validate_longitude_deg(longitude_deg)
    latitude = _validate_latitude_deg(latitude_deg)
    utc_time = time isa ZonedDateTime ? DateTime(time, UTC) : time
    declination, equation_of_time_min, utc_minute = _solar_time_terms(utc_time)
    return _zenith_from_terms(
        declination,
        equation_of_time_min,
        utc_minute,
        deg2rad(Float64(longitude)),
        deg2rad(Float64(latitude)),
    )
end

"""
    solar_zenith_batch(times, longitude_deg, latitude_deg) -> Vector{Float64}

Compute solar zenith angles for aligned timestamp, longitude, and latitude
vectors. The output preserves the input axes' linear order. Time-only terms
are cached once per unique UTC instant.
"""
function solar_zenith_batch(
        times::AbstractVector{<:Union{DateTime,ZonedDateTime}},
        longitude_deg::AbstractVector{<:Real},
        latitude_deg::AbstractVector{<:Real},
    )::Vector{Float64}
    _validate_batch_lengths(times, longitude_deg, latitude_deg)
    terms = Dict{DateTime,NTuple{3,Float64}}()
    coordinates = Dict{Tuple{Float64,Float64},NTuple{3,Float64}}()
    result = Vector{Float64}(undef, length(times))

    for i in eachindex(times, longitude_deg, latitude_deg)
        longitude = _validate_longitude_deg(longitude_deg[i])
        latitude = _validate_latitude_deg(latitude_deg[i])
        result[i] = _cached_solar_zenith(
            times[i], longitude, latitude, terms, coordinates,
        )
    end
    return result
end

"""
    solar_zenith_batch(times, longitude_deg, latitude_deg) -> Vector{Float64}

Compute solar zenith angles for timestamps at one shared coordinate. This is
the scalar-coordinate expansion form of `solar_zenith_batch`.
"""
function solar_zenith_batch(
        times::AbstractVector{<:Union{DateTime,ZonedDateTime}},
        longitude_deg::Real,
        latitude_deg::Real,
    )::Vector{Float64}
    longitude = _validate_longitude_deg(longitude_deg)
    latitude = _validate_latitude_deg(latitude_deg)
    longitude_rad = deg2rad(Float64(longitude))
    latitude_rad = deg2rad(Float64(latitude))
    terms = Dict{DateTime,NTuple{3,Float64}}()
    result = Vector{Float64}(undef, length(times))

    for i in eachindex(times)
        utc_time = _utc_datetime(times[i])
        time_terms = get!(terms, utc_time) do
            _solar_time_terms(utc_time)
        end
        result[i] = _zenith_from_terms(time_terms..., longitude_rad, latitude_rad)
    end
    return result
end

_utc_datetime(time::DateTime) = time
_utc_datetime(time::ZonedDateTime) = DateTime(time, UTC)

function _cached_solar_zenith(
        time::Union{DateTime,ZonedDateTime},
        longitude_deg::Real,
        latitude_deg::Real,
        time_terms::Dict{DateTime,NTuple{3,Float64}},
        coordinate_terms::Dict{Tuple{Float64,Float64},NTuple{3,Float64}},
    )::Float64
    longitude = Float64(longitude_deg)
    latitude = Float64(latitude_deg)
    coordinates = get!(coordinate_terms, (longitude, latitude)) do
        latitude_rad = deg2rad(latitude)
        (deg2rad(longitude), sin(latitude_rad), cos(latitude_rad))
    end
    utc_time = _utc_datetime(time)
    solar_time = get!(time_terms, utc_time) do
        _solar_time_terms(utc_time)
    end
    return _zenith_from_cached_terms(solar_time..., coordinates...)
end

# Spencer (1971), equations 1--4. The argument uses 365 days as specified by
# the published approximation, including on leap-year day 366.
function _solar_time_terms(utc_time::DateTime)::NTuple{3,Float64}
    day_of_year = Dates.dayofyear(utc_time)
    gamma = 2π * (day_of_year - 1) / 365
    declination = _spencer_declination(gamma)
    equation_of_time_min = _spencer_equation_of_time(gamma) * 720 / π
    utc_minute = (
        60 * Dates.hour(utc_time) + Dates.minute(utc_time) +
        Dates.second(utc_time) / 60 + Dates.millisecond(utc_time) / 60_000
    )
    return declination, equation_of_time_min, utc_minute
end

function _spencer_declination(gamma::Real)::Float64
    g = Float64(gamma)
    return 0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) -
           0.006758 * cos(2g) + 0.000907 * sin(2g) -
           0.002697 * cos(3g) + 0.00148 * sin(3g)
end

function _spencer_equation_of_time(gamma::Real)::Float64
    g = Float64(gamma)
    return 0.0000075 + 0.001868 * cos(g) - 0.032077 * sin(g) -
           0.014615 * cos(2g) - 0.040849 * sin(2g)
end

# `longitude_rad` is positive east. Four minutes per degree converts UTC to
# local mean solar time before the equation-of-time correction.
function _zenith_from_terms(
        declination::Real,
        equation_of_time_min::Real,
        utc_minute::Real,
        longitude_rad::Real,
        latitude_rad::Real,
    )::Float64
    hour_angle = π * (
        Float64(utc_minute) + Float64(equation_of_time_min) +
        4 * rad2deg(Float64(longitude_rad)) - 720
    ) / 720
    cos_zenith = sin(Float64(latitude_rad)) * sin(Float64(declination)) +
                 cos(Float64(latitude_rad)) * cos(Float64(declination)) * cos(hour_angle)
    return rad2deg(acos(clamp(cos_zenith, -1.0, 1.0)))
end

function _zenith_from_cached_terms(
        declination::Real,
        equation_of_time_min::Real,
        utc_minute::Real,
        longitude_rad::Real,
        sin_latitude::Real,
        cos_latitude::Real,
    )::Float64
    hour_angle = π * (
        Float64(utc_minute) + Float64(equation_of_time_min) +
        4 * rad2deg(Float64(longitude_rad)) - 720
    ) / 720
    cos_zenith = Float64(sin_latitude) * sin(Float64(declination)) +
                 Float64(cos_latitude) * cos(Float64(declination)) * cos(hour_angle)
    return rad2deg(acos(clamp(cos_zenith, -1.0, 1.0)))
end
