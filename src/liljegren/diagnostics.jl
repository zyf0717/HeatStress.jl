"""Construct an unattempted component diagnostic after input preparation fails."""
function _not_attempted_diagnostics(config::SolverConfig{T}) where {T<:AbstractFloat}
    return SolverDiagnostics{T}(
        false,
        NotAttempted,
        missing,
        missing,
        missing,
        0,
        0,
        missing,
        missing,
        missing,
        missing,
        missing,
        missing,
        config.root_tolerance_k,
        config.residual_tolerance_k,
    )
end

"""Location result plus its independent residual validation, before materialization."""
struct _ValidatedComponentSolve{T<:AbstractFloat}
    location::_BracketedSolveResult{T}
    validation_residual_k::Union{Missing,T}
    validation_evaluations::Int
end

@inline function _validated_component_solve(
    location::_BracketedSolveResult{T},
    validation_residual_k::Union{Missing,T},
    validation_evaluations::Int,
) where {T<:AbstractFloat}
    validation_evaluations >= 0 || throw(ArgumentError("validation_evaluations must be non-negative"))
    return _ValidatedComponentSolve{T}(location, validation_residual_k, validation_evaluations)
end

@inline function _accepted_component_value(
    component::_ValidatedComponentSolve{T},
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    location = component.location
    accepted = location.converged && !ismissing(location.candidate_k) &&
               !ismissing(component.validation_residual_k) && isfinite(component.validation_residual_k) &&
               abs(component.validation_residual_k) <= config.residual_tolerance_k
    return accepted ? location.candidate_k - convert(T, KELVIN_OFFSET) : missing
end

"""Convert a location result and independent validation residual into diagnostics."""
function _solver_diagnostics(
    solve::_BracketedSolveResult{T},
    validation_residual_k::Union{Missing,T},
    config::SolverConfig{T},
    validation_evaluations::Int = 0,
) where {T<:AbstractFloat}
    component = _validated_component_solve(solve, validation_residual_k, validation_evaluations)
    candidate_c = ismissing(solve.candidate_k) ? missing : solve.candidate_k - convert(T, KELVIN_OFFSET)
    value_c = _accepted_component_value(component, config)
    accepted = !ismissing(value_c)
    reason = solve.converged ? (accepted ? NoFailure : ResidualValidationFailed) : solve.reason

    return SolverDiagnostics{T}(
        accepted,
        reason,
        value_c,
        candidate_c,
        validation_residual_k,
        solve.evaluations + component.validation_evaluations,
        solve.iterations,
        solve.initial_lower_k,
        solve.initial_upper_k,
        solve.final_lower_k,
        solve.final_upper_k,
        solve.lower_location_residual,
        solve.upper_location_residual,
        config.root_tolerance_k,
        config.residual_tolerance_k,
    )
end
