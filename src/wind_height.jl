struct _WindHeightResolution{T<:AbstractFloat}
    wind_speed_at_reference_height_m_s::T
    effective_wind_speed_m_s::T
    diagnostics::WindHeightDiagnostics{T}
end

struct _WindHeightFailure{T<:AbstractFloat}
    status::InputStatus
    diagnostics::WindHeightDiagnostics{T}
end

function _validate_wind_height_policy_inputs(
    policy::WindHeightPolicy,
    stability_class,
    vertical_temperature_difference_c,
)
    if policy isa NoWindHeightAdjustment &&
       (!isnothing(stability_class) || !isnothing(vertical_temperature_difference_c))
        throw(ArgumentError(
            "stability_class and vertical_temperature_difference_c require an active wind-height policy",
        ))
    end
    return nothing
end

@inline function _empty_wind_height_diagnostics(
    ::Type{T};
    supplied_wind_speed_m_s = missing,
    measurement_height_m = missing,
    reference_height_m = T(2),
) where {T<:AbstractFloat}
    supplied = ismissing(supplied_wind_speed_m_s) ? missing : convert(T, supplied_wind_speed_m_s)
    measurement = ismissing(measurement_height_m) ? missing : convert(T, measurement_height_m)
    reference = ismissing(reference_height_m) ? missing : convert(T, reference_height_m)
    return WindHeightDiagnostics{T}(
        supplied,
        measurement,
        reference,
        missing,
        missing,
        nothing,
        nothing,
        false,
        false,
        false,
    )
end

@inline function _daytime_stability_class(wind::T, ghi::T) where {T<:AbstractFloat}
    if wind < T(2)
        return ghi >= T(675) ? StabilityA : ghi >= T(175) ? StabilityB : StabilityD
    elseif wind < T(3)
        return ghi >= T(925) ? StabilityA : ghi >= T(675) ? StabilityB : ghi >= T(175) ? StabilityC : StabilityD
    elseif wind < T(5)
        return ghi >= T(925) ? StabilityB : ghi >= T(675) ? StabilityB : ghi >= T(175) ? StabilityC : StabilityD
    elseif wind < T(6)
        return ghi >= T(925) ? StabilityC : ghi >= T(675) ? StabilityC : StabilityD
    end
    return ghi >= T(925) ? StabilityC : ghi >= T(675) ? StabilityD : StabilityD
end

@inline function _nighttime_stability_class(wind::T, delta_temperature::T) where {T<:AbstractFloat}
    if wind < T(2)
        return delta_temperature < zero(T) ? StabilityE : StabilityF
    elseif wind < T(2.5)
        return delta_temperature < zero(T) ? StabilityD : StabilityE
    end
    return StabilityD
end

@inline function _power_law_exponent(
    stability::PasquillStabilityClass,
    ::Rural,
    ::Type{T},
) where {T<:AbstractFloat}
    stability === StabilityA && return T(7) / T(100)
    stability === StabilityB && return T(7) / T(100)
    stability === StabilityC && return T(1) / T(10)
    stability === StabilityD && return T(15) / T(100)
    stability === StabilityE && return T(35) / T(100)
    return T(55) / T(100)
end

@inline function _power_law_exponent(
    stability::PasquillStabilityClass,
    ::Urban,
    ::Type{T},
) where {T<:AbstractFloat}
    stability === StabilityA && return T(15) / T(100)
    stability === StabilityB && return T(15) / T(100)
    stability === StabilityC && return T(20) / T(100)
    stability === StabilityD && return T(25) / T(100)
    return T(30) / T(100)
end

function _resolve_wind_height(
    supplied_wind_speed_m_s::T,
    nonnegative_wind_speed_m_s::T,
    measurement_height_m::Union{Missing,T};
    reference_height_m::T,
    policy::WindHeightPolicy,
    terrain::WindTerrain,
    stability_class::Union{Nothing,PasquillStabilityClass},
    daytime::Union{Nothing,Bool},
    ghi_w_m2::Union{Nothing,Missing,T},
    vertical_temperature_difference_c::Union{Nothing,Missing,T},
    minimum_wind_speed_m_s::Union{Nothing,T},
) where {T<:AbstractFloat}
    partial = _empty_wind_height_diagnostics(
        T;
        supplied_wind_speed_m_s,
        measurement_height_m,
        reference_height_m,
    )
    if ismissing(measurement_height_m)
        return _WindHeightFailure(MissingMeteorology, partial)
    end

    wind = nonnegative_wind_speed_m_s
    measurement_height = measurement_height_m
    all(isfinite, (supplied_wind_speed_m_s, wind, measurement_height, reference_height_m)) &&
        wind >= zero(T) && measurement_height > zero(T) && reference_height_m > zero(T) ||
        return _WindHeightFailure(InvalidDomain, partial)
    if !isnothing(minimum_wind_speed_m_s)
        isfinite(minimum_wind_speed_m_s) && minimum_wind_speed_m_s >= zero(T) ||
            return _WindHeightFailure(InvalidDomain, partial)
    end

    selected_class = nothing
    exponent = nothing
    adjusted = wind
    class_supplied = !isnothing(stability_class)

    if policy isa NoWindHeightAdjustment
        isnothing(stability_class) && isnothing(vertical_temperature_difference_c) ||
            return _WindHeightFailure(InvalidDomain, partial)
    else
        if class_supplied
            selected_class = stability_class
        elseif isnothing(daytime)
            return _WindHeightFailure(MissingMeteorology, partial)
        elseif daytime
            if isnothing(ghi_w_m2) || ismissing(ghi_w_m2)
                return _WindHeightFailure(MissingMeteorology, partial)
            end
            isfinite(ghi_w_m2) && ghi_w_m2 >= zero(T) ||
                return _WindHeightFailure(InvalidDomain, partial)
            selected_class = _daytime_stability_class(wind, ghi_w_m2)
        else
            if isnothing(vertical_temperature_difference_c) ||
               ismissing(vertical_temperature_difference_c)
                return _WindHeightFailure(MissingMeteorology, partial)
            end
            isfinite(vertical_temperature_difference_c) ||
                return _WindHeightFailure(InvalidDomain, partial)
            selected_class = _nighttime_stability_class(
                wind,
                vertical_temperature_difference_c,
            )
        end
        exponent = _power_law_exponent(selected_class, terrain, T)
        adjusted = wind * (reference_height_m / measurement_height)^exponent
        isfinite(adjusted) || return _WindHeightFailure(InvalidDomain, partial)
    end

    effective = isnothing(minimum_wind_speed_m_s) ?
        adjusted : max(adjusted, minimum_wind_speed_m_s)
    floor_applied = !isnothing(minimum_wind_speed_m_s) && effective > adjusted
    diagnostics = WindHeightDiagnostics{T}(
        supplied_wind_speed_m_s,
        measurement_height,
        reference_height_m,
        adjusted,
        effective,
        selected_class,
        exponent,
        class_supplied,
        policy isa LiljegrenStabilityPowerLaw && measurement_height != reference_height_m,
        floor_applied,
    )
    return _WindHeightResolution(adjusted, effective, diagnostics)
end

function _standalone_wind_type(values...)
    numeric_types = map(values) do value
        isnothing(value) ? Union{} : typeof(float(value))
    end
    return promote_type(numeric_types...)
end

function _standalone_wind_resolution(
    speed_m_s::Real,
    measurement_height_m::Real;
    reference_height_m::Real,
    policy::WindHeightPolicy,
    terrain::WindTerrain,
    stability_class::Union{Nothing,PasquillStabilityClass},
    daytime::Union{Nothing,Bool},
    ghi_w_m2::Union{Nothing,Real},
    vertical_temperature_difference_c::Union{Nothing,Real},
    minimum_wind_speed_m_s::Union{Nothing,Real},
)
    T = _standalone_wind_type(
        speed_m_s,
        measurement_height_m,
        reference_height_m,
        ghi_w_m2,
        vertical_temperature_difference_c,
        minimum_wind_speed_m_s,
    )
    speed = convert(T, speed_m_s)
    speed >= zero(T) || throw(ArgumentError("speed_m_s must be non-negative"))
    resolution = _resolve_wind_height(
        speed,
        speed,
        convert(T, measurement_height_m);
        reference_height_m = convert(T, reference_height_m),
        policy,
        terrain,
        stability_class,
        daytime,
        ghi_w_m2 = isnothing(ghi_w_m2) ? nothing : convert(T, ghi_w_m2),
        vertical_temperature_difference_c = isnothing(vertical_temperature_difference_c) ?
            nothing : convert(T, vertical_temperature_difference_c),
        minimum_wind_speed_m_s = isnothing(minimum_wind_speed_m_s) ?
            nothing : convert(T, minimum_wind_speed_m_s),
    )
    resolution isa _WindHeightFailure && throw(ArgumentError(
        resolution.status === MissingMeteorology ?
        "automatic stability classification requires its daytime or nighttime meteorology" :
        "wind-height inputs must be finite and in their valid domains",
    ))
    return resolution
end

"""
    wind_speed_at_height(speed_m_s, measurement_height_m; reference_height_m=2.0, ...)

Convert nonnegative wind to a reference height using an explicit wind-height
policy. Automatic stability classification requires `daytime=true` with GHI,
or `daytime=false` with upper-minus-lower vertical temperature difference.
"""
function wind_speed_at_height(
    speed_m_s::Real,
    measurement_height_m::Real;
    reference_height_m::Real = 2.0,
    policy::WindHeightPolicy = LiljegrenStabilityPowerLaw(),
    terrain::WindTerrain = Rural(),
    stability_class::Union{Nothing,PasquillStabilityClass} = nothing,
    daytime::Union{Nothing,Bool} = nothing,
    ghi_w_m2::Union{Nothing,Real} = nothing,
    vertical_temperature_difference_c::Union{Nothing,Real} = nothing,
    minimum_wind_speed_m_s::Union{Nothing,Real} = nothing,
)
    resolution = _standalone_wind_resolution(
        speed_m_s,
        measurement_height_m;
        reference_height_m,
        policy,
        terrain,
        stability_class,
        daytime,
        ghi_w_m2,
        vertical_temperature_difference_c,
        minimum_wind_speed_m_s,
    )
    return resolution.effective_wind_speed_m_s
end

"""Return a complete trace for `wind_speed_at_height`."""
function diagnose_wind_speed_at_height(
    speed_m_s::Real,
    measurement_height_m::Real;
    reference_height_m::Real = 2.0,
    policy::WindHeightPolicy = LiljegrenStabilityPowerLaw(),
    terrain::WindTerrain = Rural(),
    stability_class::Union{Nothing,PasquillStabilityClass} = nothing,
    daytime::Union{Nothing,Bool} = nothing,
    ghi_w_m2::Union{Nothing,Real} = nothing,
    vertical_temperature_difference_c::Union{Nothing,Real} = nothing,
    minimum_wind_speed_m_s::Union{Nothing,Real} = nothing,
)
    return _standalone_wind_resolution(
        speed_m_s,
        measurement_height_m;
        reference_height_m,
        policy,
        terrain,
        stability_class,
        daytime,
        ghi_w_m2,
        vertical_temperature_difference_c,
        minimum_wind_speed_m_s,
    ).diagnostics
end
