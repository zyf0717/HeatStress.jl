struct _GlobeEnergyResidual{T<:AbstractFloat}
    balance::GlobeBalance{T}
end

@inline function (residual::_GlobeEnergyResidual{T})(temperature_k::T)::T where {T<:AbstractFloat}
    return _globe_energy_residual_k4(temperature_k, residual.balance)
end

"""Locate and independently validate a prepared globe balance."""
function _solve_globe_balance_data(
    balance::GlobeBalance{T},
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    air_temperature_k = balance.air_temperature_k
    solve = _solve_bracketed(
        _GlobeEnergyResidual{T}(balance),
        air_temperature_k - convert(T, 2),
        air_temperature_k + convert(T, 10),
        _GlobeBracketExpansion(),
        air_temperature_k - convert(T, 200),
        air_temperature_k + convert(T, 200),
        config,
    )
    if solve.converged && !ismissing(solve.candidate_k)
        validation_residual_k = _globe_fixed_point_residual_k(solve.candidate_k, balance)
        return _validated_component_solve(solve, validation_residual_k, 1)
    end
    return _validated_component_solve(solve, missing, 0)
end

"""Solve and validate a prepared globe balance; all temperatures are Kelvin internally."""
function _solve_globe_balance(
    balance::GlobeBalance{T},
    config::SolverConfig{T},
) where {T<:AbstractFloat}
    component = _solve_globe_balance_data(balance, config)
    return _solver_diagnostics(
        component.location,
        component.validation_residual_k,
        config,
        component.validation_evaluations,
    )
end
