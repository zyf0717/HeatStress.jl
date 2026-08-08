"""Value-only estimated-WBGT outcome; WBGT and component temperatures are °C."""
struct WBGTResult{T<:AbstractFloat}
    wbgt_c::Union{Missing,T}
    natural_wet_bulb_c::Union{Missing,T}
    globe_temperature_c::Union{Missing,T}

    function WBGTResult{T}(
        wbgt_c::Union{Missing,T},
        natural_wet_bulb_c::Union{Missing,T},
        globe_temperature_c::Union{Missing,T},
    ) where {T<:AbstractFloat}
        return new{T}(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
    end
end

function WBGTResult(
    wbgt_c::Union{Missing,Real},
    natural_wet_bulb_c::Union{Missing,Real},
    globe_temperature_c::Union{Missing,Real},
)
    float_type = _common_float_type(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
    return WBGTResult{float_type}(
        _convert_or_missing(float_type, wbgt_c),
        _convert_or_missing(float_type, natural_wet_bulb_c),
        _convert_or_missing(float_type, globe_temperature_c),
    )
end

"""Aligned estimated-WBGT result; each array contains °C values or `missing`."""
struct WBGTBatchResult{T<:AbstractFloat,VW<:AbstractVector,VN<:AbstractVector,VG<:AbstractVector}
    wbgt_c::VW
    natural_wet_bulb_c::VN
    globe_temperature_c::VG
end

function _validate_batch_result_vectors(::Type{T}, outputs::AbstractVector...) where {T<:AbstractFloat}
    isempty(outputs) && throw(ArgumentError("batch result requires output vectors"))
    rows = length(first(outputs))
    for output in outputs
        length(output) == rows ||
            throw(ArgumentError("batch result vectors must have identical lengths"))
        Missing <: eltype(output) && T <: eltype(output) ||
            throw(ArgumentError("batch result element type must accept Missing and $T"))
    end
    return nothing
end

function WBGTBatchResult{T}(
    wbgt_c::VW,
    natural_wet_bulb_c::VN,
    globe_temperature_c::VG,
) where {T<:AbstractFloat,VW<:AbstractVector,VN<:AbstractVector,VG<:AbstractVector}
    _validate_batch_result_vectors(T, wbgt_c, natural_wet_bulb_c, globe_temperature_c)
    return WBGTBatchResult{T,VW,VN,VG}(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
end

function WBGTBatchResult(
    wbgt_c::VW,
    natural_wet_bulb_c::VN,
    globe_temperature_c::VG,
) where {VW<:AbstractVector,VN<:AbstractVector,VG<:AbstractVector}
    element_types = (Base.nonmissingtype(eltype(wbgt_c)),
                     Base.nonmissingtype(eltype(natural_wet_bulb_c)),
                     Base.nonmissingtype(eltype(globe_temperature_c)))
    all(isconcretetype, element_types) && all(type -> type <: AbstractFloat, element_types) ||
        throw(ArgumentError("WBGTBatchResult{T} is required for non-floating or broad output element types"))
    return WBGTBatchResult{promote_type(element_types...)}(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
end
