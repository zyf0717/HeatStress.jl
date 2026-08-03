"""Policy controlling conversion of measured wind to the model reference height."""
abstract type WindHeightPolicy end

"""Preserve supplied wind without height conversion."""
struct NoWindHeightAdjustment <: WindHeightPolicy end

"""Use the EPA stability-dependent power-law wind profile."""
struct LiljegrenStabilityPowerLaw <: WindHeightPolicy end

"""Terrain family selecting a stability-dependent power-law exponent."""
abstract type WindTerrain end

struct Rural <: WindTerrain end
struct Urban <: WindTerrain end

"""Pasquill-Gifford atmospheric stability class."""
@enum PasquillStabilityClass::UInt8 begin
    StabilityA = 1
    StabilityB = 2
    StabilityC = 3
    StabilityD = 4
    StabilityE = 5
    StabilityF = 6
end

"""Wind-height conversion trace; heights are m and wind fields are m/s."""
struct WindHeightDiagnostics{T<:AbstractFloat}
    supplied_wind_speed_m_s::Union{Missing,T}
    measurement_height_m::Union{Missing,T}
    reference_height_m::Union{Missing,T}
    wind_speed_at_reference_height_m_s::Union{Missing,T}
    effective_wind_speed_m_s::Union{Missing,T}
    stability_class::Union{Nothing,PasquillStabilityClass}
    power_law_exponent::Union{Nothing,T}
    stability_class_supplied::Bool
    height_adjusted::Bool
    minimum_wind_floor_applied::Bool

    function WindHeightDiagnostics{T}(
        supplied_wind_speed_m_s::Union{Missing,T},
        measurement_height_m::Union{Missing,T},
        reference_height_m::Union{Missing,T},
        wind_speed_at_reference_height_m_s::Union{Missing,T},
        effective_wind_speed_m_s::Union{Missing,T},
        stability_class::Union{Nothing,PasquillStabilityClass},
        power_law_exponent::Union{Nothing,T},
        stability_class_supplied::Bool,
        height_adjusted::Bool,
        minimum_wind_floor_applied::Bool,
    ) where {T<:AbstractFloat}
        return new{T}(
            supplied_wind_speed_m_s,
            measurement_height_m,
            reference_height_m,
            wind_speed_at_reference_height_m_s,
            effective_wind_speed_m_s,
            stability_class,
            power_law_exponent,
            stability_class_supplied,
            height_adjusted,
            minimum_wind_floor_applied,
        )
    end
end

"""Structure-of-arrays wind-height diagnostics for aligned Liljegren rows."""
struct WindHeightDiagnosticsBatch{T<:AbstractFloat}
    supplied_wind_speed_m_s::Vector{Union{Missing,T}}
    measurement_height_m::Vector{Union{Missing,T}}
    reference_height_m::Vector{Union{Missing,T}}
    wind_speed_at_reference_height_m_s::Vector{Union{Missing,T}}
    effective_wind_speed_m_s::Vector{Union{Missing,T}}
    stability_class::Vector{Union{Nothing,PasquillStabilityClass}}
    power_law_exponent::Vector{Union{Nothing,T}}
    stability_class_supplied::Vector{Bool}
    height_adjusted::Vector{Bool}
    minimum_wind_floor_applied::Vector{Bool}

    function WindHeightDiagnosticsBatch{T}(
        supplied_wind_speed_m_s::Vector{Union{Missing,T}},
        measurement_height_m::Vector{Union{Missing,T}},
        reference_height_m::Vector{Union{Missing,T}},
        wind_speed_at_reference_height_m_s::Vector{Union{Missing,T}},
        effective_wind_speed_m_s::Vector{Union{Missing,T}},
        stability_class::Vector{Union{Nothing,PasquillStabilityClass}},
        power_law_exponent::Vector{Union{Nothing,T}},
        stability_class_supplied::Vector{Bool},
        height_adjusted::Vector{Bool},
        minimum_wind_floor_applied::Vector{Bool},
    ) where {T<:AbstractFloat}
        rows = length(supplied_wind_speed_m_s)
        all(length(values) == rows for values in (
            measurement_height_m,
            reference_height_m,
            wind_speed_at_reference_height_m_s,
            effective_wind_speed_m_s,
            stability_class,
            power_law_exponent,
            stability_class_supplied,
            height_adjusted,
            minimum_wind_floor_applied,
        )) || throw(ArgumentError("batch wind diagnostic vectors must have identical lengths"))
        return new{T}(
            supplied_wind_speed_m_s,
            measurement_height_m,
            reference_height_m,
            wind_speed_at_reference_height_m_s,
            effective_wind_speed_m_s,
            stability_class,
            power_law_exponent,
            stability_class_supplied,
            height_adjusted,
            minimum_wind_floor_applied,
        )
    end
end
