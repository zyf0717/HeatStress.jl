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

"""Convert a location result and independent validation residual into diagnostics."""
function _solver_diagnostics(
    solve::_BracketedSolveResult{T},
    validation_residual_k::Union{Missing,T},
    config::SolverConfig{T},
    validation_evaluations::Int = 0,
) where {T<:AbstractFloat}
    validation_evaluations >= 0 || throw(ArgumentError("validation_evaluations must be non-negative"))
    candidate_c = ismissing(solve.candidate_k) ? missing : solve.candidate_k - convert(T, KELVIN_OFFSET)
    accepted = solve.converged && !ismissing(solve.candidate_k) &&
               !ismissing(validation_residual_k) && isfinite(validation_residual_k) &&
               abs(validation_residual_k) <= config.residual_tolerance_k
    reason = solve.converged ? (accepted ? NoFailure : ResidualValidationFailed) : solve.reason
    value_c = accepted ? candidate_c : missing

    return SolverDiagnostics{T}(
        accepted,
        reason,
        value_c,
        candidate_c,
        validation_residual_k,
        solve.evaluations + validation_evaluations,
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
