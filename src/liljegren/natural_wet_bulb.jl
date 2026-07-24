struct _NaturalWetBulbResidual{T<:AbstractFloat}
    balance::WetBulbBalance{T}
end

@inline function (residual::_NaturalWetBulbResidual{T})(temperature_k::T)::T where {T<:AbstractFloat}
    return _natural_wet_bulb_residual(temperature_k, residual.balance)
end

"""Locate and independently validate a prepared natural-wet-bulb balance."""
function _solve_natural_wet_bulb_balance_data(
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
        _NaturalWetBulbResidual{T}(balance),
        initial_lower_k,
        initial_upper_k,
        _WetBulbBracketExpansion(),
        minimum_k,
        maximum_k,
        config,
    )
    if solve.converged && !ismissing(solve.candidate_k)
        validation_residual_k = _natural_wet_bulb_residual(solve.candidate_k, balance)
        return _validated_component_solve(solve, validation_residual_k, 1)
    end
    return _validated_component_solve(solve, missing, 0)
end

"""Solve and validate a prepared natural-wet-bulb balance; inputs are Kelvin."""
function _solve_natural_wet_bulb_balance(
    balance::WetBulbBalance{T},
    dew_point_k::T,
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    component = _solve_natural_wet_bulb_balance_data(balance, dew_point_k, config)
    return _solver_diagnostics(
        component.location,
        component.validation_residual_k,
        config,
        component.validation_evaluations,
    )
end
