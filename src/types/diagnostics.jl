"""Component-solver trace: `*_c` fields are °C and residual/tolerance fields are K."""
struct SolverDiagnostics{T<:AbstractFloat}
    converged::Bool
    reason::FailureReason
    value_c::Union{Missing,T}
    candidate_c::Union{Missing,T}
    validation_residual_k::Union{Missing,T}
    evaluations::Int
    iterations::Int
    initial_lower_k::Union{Missing,T}
    initial_upper_k::Union{Missing,T}
    final_lower_k::Union{Missing,T}
    final_upper_k::Union{Missing,T}
    lower_location_residual::Union{Missing,T}
    upper_location_residual::Union{Missing,T}
    root_tolerance_k::T
    residual_tolerance_k::T

    function SolverDiagnostics{T}(
        converged::Bool,
        reason::FailureReason,
        value_c::Union{Missing,T},
        candidate_c::Union{Missing,T},
        validation_residual_k::Union{Missing,T},
        evaluations::Int,
        iterations::Int,
        initial_lower_k::Union{Missing,T},
        initial_upper_k::Union{Missing,T},
        final_lower_k::Union{Missing,T},
        final_upper_k::Union{Missing,T},
        lower_location_residual::Union{Missing,T},
        upper_location_residual::Union{Missing,T},
        root_tolerance_k::T,
        residual_tolerance_k::T,
    ) where {T<:AbstractFloat}
        evaluations >= 0 || throw(ArgumentError("evaluations must be non-negative"))
        iterations >= 0 || throw(ArgumentError("iterations must be non-negative"))
        _require_finite_positive(root_tolerance_k, :root_tolerance_k)
        _require_finite_positive(residual_tolerance_k, :residual_tolerance_k)
        residual_tolerance_k <= T(0.01) ||
            throw(ArgumentError("residual_tolerance_k must not exceed 0.01 K"))
        return new{T}(
            converged,
            reason,
            value_c,
            candidate_c,
            validation_residual_k,
            evaluations,
            iterations,
            initial_lower_k,
            initial_upper_k,
            final_lower_k,
            final_upper_k,
            lower_location_residual,
            upper_location_residual,
            root_tolerance_k,
            residual_tolerance_k,
        )
    end
end

"""Value result (°C) plus unitless input-normalisation flags and solver diagnostics."""
struct DiagnosticWBGTResult{T<:AbstractFloat}
    result::WBGTResult{T}
    input_status::InputStatus
    dew_point_adjusted::Bool
    wind_speed_clamped::Bool
    solar_radiation_clamped::Bool
    solar_geometry_mismatch::Bool
    direct_solar_clipped::Bool
    wind_height::WindHeightDiagnostics{T}
    irradiance::IrradianceDiagnostics{T}
    globe::SolverDiagnostics{T}
    natural_wet_bulb::SolverDiagnostics{T}

    function DiagnosticWBGTResult{T}(
        result::WBGTResult{T},
        input_status::InputStatus,
        dew_point_adjusted::Bool,
        wind_speed_clamped::Bool,
        solar_radiation_clamped::Bool,
        solar_geometry_mismatch::Bool,
        direct_solar_clipped::Bool,
        wind_height::WindHeightDiagnostics{T},
        irradiance::IrradianceDiagnostics{T},
        globe::SolverDiagnostics{T},
        natural_wet_bulb::SolverDiagnostics{T},
    ) where {T<:AbstractFloat}
        return new{T}(
            result,
            input_status,
            dew_point_adjusted,
            wind_speed_clamped,
            solar_radiation_clamped,
            solar_geometry_mismatch,
            direct_solar_clipped,
            wind_height,
            irradiance,
            globe,
            natural_wet_bulb,
        )
    end
end

"""Structure-of-arrays component diagnostics for aligned Liljegren batch rows."""
struct SolverDiagnosticsBatch{T<:AbstractFloat}
    converged::Vector{Bool}
    reason::Vector{FailureReason}
    value_c::Vector{Union{Missing,T}}
    candidate_c::Vector{Union{Missing,T}}
    validation_residual_k::Vector{Union{Missing,T}}
    evaluations::Vector{Int}
    iterations::Vector{Int}
    initial_lower_k::Vector{Union{Missing,T}}
    initial_upper_k::Vector{Union{Missing,T}}
    final_lower_k::Vector{Union{Missing,T}}
    final_upper_k::Vector{Union{Missing,T}}
    lower_location_residual::Vector{Union{Missing,T}}
    upper_location_residual::Vector{Union{Missing,T}}

    function SolverDiagnosticsBatch{T}(
        converged::Vector{Bool},
        reason::Vector{FailureReason},
        value_c::Vector{Union{Missing,T}},
        candidate_c::Vector{Union{Missing,T}},
        validation_residual_k::Vector{Union{Missing,T}},
        evaluations::Vector{Int},
        iterations::Vector{Int},
        initial_lower_k::Vector{Union{Missing,T}},
        initial_upper_k::Vector{Union{Missing,T}},
        final_lower_k::Vector{Union{Missing,T}},
        final_upper_k::Vector{Union{Missing,T}},
        lower_location_residual::Vector{Union{Missing,T}},
        upper_location_residual::Vector{Union{Missing,T}},
    ) where {T<:AbstractFloat}
        rows = length(converged)
        all(length(values) == rows for values in (
            reason, value_c, candidate_c, validation_residual_k, evaluations, iterations,
            initial_lower_k, initial_upper_k, final_lower_k, final_upper_k,
            lower_location_residual, upper_location_residual,
        )) || throw(ArgumentError("batch diagnostic vectors must have identical lengths"))
        return new{T}(
            converged, reason, value_c, candidate_c, validation_residual_k, evaluations,
            iterations, initial_lower_k, initial_upper_k, final_lower_k, final_upper_k,
            lower_location_residual, upper_location_residual,
        )
    end
end

"""Structure-of-arrays diagnostic result for aligned Liljegren batch rows."""
struct DiagnosticWBGTBatchResult{T<:AbstractFloat}
    result::WBGTBatchResult{T}
    input_status::Vector{InputStatus}
    dew_point_adjusted::Vector{Bool}
    wind_speed_clamped::Vector{Bool}
    solar_radiation_clamped::Vector{Bool}
    solar_geometry_mismatch::Vector{Bool}
    direct_solar_clipped::Vector{Bool}
    wind_height::WindHeightDiagnosticsBatch{T}
    irradiance::IrradianceDiagnosticsBatch{T}
    globe::SolverDiagnosticsBatch{T}
    natural_wet_bulb::SolverDiagnosticsBatch{T}
    threaded::Bool
    threads_available::Int
    rows::Int
end
