const _MaybeReal = Union{Missing,Real}

@inline function _require_finite(value::T, name::AbstractString) where {T<:AbstractFloat}
    isfinite(value) || throw(DomainError(value, "$name must be finite"))
    return value
end
