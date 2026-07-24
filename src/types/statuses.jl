"""Unitless policy for reconciling a dew point that exceeds air temperature."""
@enum DewPointPolicy::UInt8 begin
    ClampDewPoint
    SwapAirAndDewPoint
    RejectInvalidDewPoint
end

"""Unitless public-input disposition for a scalar or batch row."""
@enum InputStatus::UInt8 begin
    InputAccepted
    MissingMeteorology
    MissingTime
    InvalidDewPoint
    InvalidDomain
end

"""Unitless reason a numerical component solve did not produce an accepted root."""
@enum FailureReason::UInt8 begin
    NoFailure
    NotAttempted
    Unbracketed
    NonFiniteResidual
    ResidualValidationFailed
    IterationLimit
end

function _common_float_type(values::Vararg{Union{Missing,Real}})
    T = nothing
    for value in values
        ismissing(value) && continue
        value_type = typeof(float(value))
        T = isnothing(T) ? value_type : promote_type(T, value_type)
    end
    return isnothing(T) ? Float64 : T
end

_convert_or_missing(::Type{T}, ::Missing) where {T<:AbstractFloat} = missing
_convert_or_missing(::Type{T}, value::Real) where {T<:AbstractFloat} = convert(T, value)

function _require_finite_positive(value::T, name::Symbol) where {T<:AbstractFloat}
    isfinite(value) && value > zero(T) || throw(ArgumentError("$name must be finite and positive"))
    return value
end

function _require_finite_nonnegative(value::T, name::Symbol) where {T<:AbstractFloat}
    isfinite(value) && value >= zero(T) || throw(ArgumentError("$name must be finite and non-negative"))
    return value
end
