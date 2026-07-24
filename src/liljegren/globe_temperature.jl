"""Solve and validate a prepared globe balance; all temperatures are Kelvin internally."""
function _solve_globe_balance(
    balance::GlobeBalance{T},
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    air_temperature_k = balance.air_temperature_k
    solve = _solve_bracketed(
        temperature_k -> _globe_energy_residual_k4(temperature_k, balance),
        air_temperature_k - convert(T, 2),
        air_temperature_k + convert(T, 10),
        _GlobeBracketExpansion(),
        air_temperature_k - convert(T, 200),
        air_temperature_k + convert(T, 200),
        config,
    )
    validation_residual_k = ismissing(solve.candidate_k) ?
                            missing : _globe_fixed_point_residual_k(solve.candidate_k, balance)
    return _solver_diagnostics(solve, validation_residual_k, config)
end
