"""Internal result of locating a root in a signed residual equation."""
struct _BracketedSolveResult{T<:AbstractFloat}
    converged::Bool
    reason::FailureReason
    candidate_k::Union{Missing,T}
    evaluations::Int
    iterations::Int
    initial_lower_k::T
    initial_upper_k::T
    final_lower_k::T
    final_upper_k::T
    lower_location_residual::T
    upper_location_residual::T
end

abstract type _BracketExpansionPolicy end

"""Expand a monotone increasing globe balance in the required direction."""
struct _GlobeBracketExpansion <: _BracketExpansionPolicy end

"""Expand both natural-wet-bulb endpoints by at most ten kelvin per cycle."""
struct _WetBulbBracketExpansion <: _BracketExpansionPolicy end

@inline _same_sign(left::T, right::T) where {T<:AbstractFloat} =
    (left < zero(T) && right < zero(T)) || (left > zero(T) && right > zero(T))

@inline _sign_change(left::T, right::T) where {T<:AbstractFloat} =
    (left < zero(T) && right > zero(T)) || (left > zero(T) && right < zero(T))

@inline function _call_residual(residual, temperature_k::T) where {T<:AbstractFloat}
    value = residual(temperature_k)
    value isa Real || throw(ArgumentError("residual must return a real scalar"))
    return convert(T, value)
end

@inline function _next_lower(
    ::_GlobeBracketExpansion,
    lower_k::T,
    upper_k::T,
    lower_residual::T,
    upper_residual::T,
    minimum_k::T,
) where {T<:AbstractFloat}
    _same_sign(lower_residual, upper_residual) && lower_residual > zero(T) || return lower_k
    return max(minimum_k, lower_k - (upper_k - lower_k))
end

@inline function _next_upper(
    ::_GlobeBracketExpansion,
    lower_k::T,
    upper_k::T,
    lower_residual::T,
    upper_residual::T,
    maximum_k::T,
) where {T<:AbstractFloat}
    _same_sign(lower_residual, upper_residual) && upper_residual < zero(T) || return upper_k
    return min(maximum_k, upper_k + (upper_k - lower_k))
end

@inline function _next_lower(
    ::_WetBulbBracketExpansion,
    lower_k::T,
    ::T,
    ::T,
    ::T,
    minimum_k::T,
) where {T<:AbstractFloat}
    return max(minimum_k, lower_k - min(convert(T, 10), lower_k - minimum_k))
end

@inline function _next_upper(
    ::_WetBulbBracketExpansion,
    ::T,
    upper_k::T,
    ::T,
    ::T,
    maximum_k::T,
) where {T<:AbstractFloat}
    return min(maximum_k, upper_k + min(convert(T, 10), maximum_k - upper_k))
end

@inline function _solve_result(
    converged::Bool,
    reason::FailureReason,
    candidate_k::Union{Missing,T},
    evaluations::Int,
    iterations::Int,
    initial_lower_k::T,
    initial_upper_k::T,
    lower_k::T,
    upper_k::T,
    lower_residual::T,
    upper_residual::T,
) where {T<:AbstractFloat}
    return _BracketedSolveResult(
        converged,
        reason,
        candidate_k,
        evaluations,
        iterations,
        initial_lower_k,
        initial_upper_k,
        lower_k,
        upper_k,
        lower_residual,
        upper_residual,
    )
end

"""Locate a root of a signed scalar residual using safeguarded bisection.

The residual's native units are retained in the returned endpoint diagnostics.
This function only establishes root location; component code performs the
separate Kelvin-scale residual acceptance check.
"""
function _solve_bracketed(
    residual,
    initial_lower_k::T,
    initial_upper_k::T,
    expansion_policy::_BracketExpansionPolicy,
    minimum_k::T,
    maximum_k::T,
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    isfinite(minimum_k) && isfinite(maximum_k) && minimum_k <= initial_lower_k <=
        initial_upper_k <= maximum_k ||
        throw(ArgumentError("bracket bounds must be finite and ordered within the search bounds"))

    lower_k = initial_lower_k
    upper_k = initial_upper_k
    lower_residual = _call_residual(residual, lower_k)
    upper_residual = _call_residual(residual, upper_k)
    evaluations = 2
    iterations = 0

    if !isfinite(lower_residual) || !isfinite(upper_residual)
        return _solve_result(
            false,
            NonFiniteResidual,
            missing,
            evaluations,
            iterations,
            initial_lower_k,
            initial_upper_k,
            lower_k,
            upper_k,
            lower_residual,
            upper_residual,
        )
    elseif iszero(lower_residual)
        return _solve_result(
            true,
            NoFailure,
            lower_k,
            evaluations,
            iterations,
            initial_lower_k,
            initial_upper_k,
            lower_k,
            upper_k,
            lower_residual,
            upper_residual,
        )
    elseif iszero(upper_residual)
        return _solve_result(
            true,
            NoFailure,
            upper_k,
            evaluations,
            iterations,
            initial_lower_k,
            initial_upper_k,
            lower_k,
            upper_k,
            lower_residual,
            upper_residual,
        )
    end

    while !_sign_change(lower_residual, upper_residual)
        lower_changed = false
        next_lower_k = _next_lower(
            expansion_policy,
            lower_k,
            upper_k,
            lower_residual,
            upper_residual,
            minimum_k,
        )
        if next_lower_k != lower_k
            lower_changed = true
            lower_k = next_lower_k
            lower_residual = _call_residual(residual, lower_k)
            evaluations += 1
            if !isfinite(lower_residual)
                return _solve_result(false, NonFiniteResidual, missing, evaluations, iterations,
                    initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
            elseif iszero(lower_residual)
                return _solve_result(true, NoFailure, lower_k, evaluations, iterations,
                    initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
            elseif _sign_change(lower_residual, upper_residual)
                break
            end
        end

        next_upper_k = _next_upper(
            expansion_policy,
            lower_k,
            upper_k,
            lower_residual,
            upper_residual,
            maximum_k,
        )
        if next_upper_k == upper_k
            # A globe same-positive bracket moves only downward. It is
            # unbracketed only after neither endpoint can move further.
            lower_changed && continue
            return _solve_result(false, Unbracketed, missing, evaluations, iterations,
                initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
        end
        upper_k = next_upper_k
        upper_residual = _call_residual(residual, upper_k)
        evaluations += 1
        if !isfinite(upper_residual)
            return _solve_result(false, NonFiniteResidual, missing, evaluations, iterations,
                initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
        elseif iszero(upper_residual)
            return _solve_result(true, NoFailure, upper_k, evaluations, iterations,
                initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
        end
    end

    if upper_k - lower_k <= config.root_tolerance_k
        return _solve_result(true, NoFailure, lower_k + (upper_k - lower_k) / convert(T, 2), evaluations,
            iterations, initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
    end

    last_midpoint_k = missing
    while iterations < config.maximum_iterations
        midpoint_k = lower_k + (upper_k - lower_k) / convert(T, 2)
        adjacent = midpoint_k == lower_k || midpoint_k == upper_k
        midpoint_residual = _call_residual(residual, midpoint_k)
        evaluations += 1
        iterations += 1
        last_midpoint_k = midpoint_k

        if !isfinite(midpoint_residual)
            return _solve_result(false, NonFiniteResidual, midpoint_k, evaluations, iterations,
                initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
        elseif iszero(midpoint_residual)
            return _solve_result(true, NoFailure, midpoint_k, evaluations, iterations,
                initial_lower_k, initial_upper_k, midpoint_k, midpoint_k, midpoint_residual, midpoint_residual)
        elseif adjacent
            candidate_k = abs(lower_residual) <= abs(upper_residual) ? lower_k : upper_k
            return _solve_result(true, NoFailure, candidate_k, evaluations, iterations,
                initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
        elseif _sign_change(lower_residual, midpoint_residual)
            upper_k = midpoint_k
            upper_residual = midpoint_residual
        else
            lower_k = midpoint_k
            lower_residual = midpoint_residual
        end

        # Float32 cannot represent a 1e-6 K-wide bracket near ordinary
        # atmospheric temperatures. Adjacent endpoints are the strongest
        # location result available in the configured floating-point type.
        if upper_k - lower_k <= config.root_tolerance_k
            return _solve_result(true, NoFailure, lower_k + (upper_k - lower_k) / convert(T, 2), evaluations,
                iterations, initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
        end
    end

    return _solve_result(false, IterationLimit, last_midpoint_k, evaluations, iterations,
        initial_lower_k, initial_upper_k, lower_k, upper_k, lower_residual, upper_residual)
end
