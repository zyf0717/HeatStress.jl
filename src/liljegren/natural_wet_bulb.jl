"""Solve and validate a prepared natural-wet-bulb balance; inputs are Kelvin."""
function _solve_natural_wet_bulb_balance(
    balance::WetBulbBalance{T},
    dew_point_k::T,
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    air_temperature_k = balance.air_temperature_k
    minimum_k = air_temperature_k - convert(T, 100)
    maximum_k = air_temperature_k + convert(T, 100)
    initial_lower_k = max(minimum_k, dew_point_k - one(T))
    initial_upper_k = min(maximum_k, air_temperature_k + one(T))
    solve = _solve_bracketed(
        temperature_k -> _natural_wet_bulb_residual(temperature_k, balance),
        initial_lower_k,
        initial_upper_k,
        _WetBulbBracketExpansion(),
        minimum_k,
        maximum_k,
        config,
    )
    validation_residual_k = ismissing(solve.candidate_k) ?
                            missing : _natural_wet_bulb_residual(solve.candidate_k, balance)
    return _solver_diagnostics(solve, validation_residual_k, config)
end
