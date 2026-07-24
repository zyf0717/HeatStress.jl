"""Policy for reconciling a dew point that exceeds air temperature."""
@enum DewPointPolicy::UInt8 begin
    ClampDewPoint
    SwapAirAndDewPoint
    RejectInvalidDewPoint
end

"""Method used to derive solar time from a supported temporal input."""
@enum SolarTimeMode::UInt8 begin
    TimestampSolarTime
    DateNoonSolarTime
end

"""Public-input disposition for a scalar or batch row."""
@enum InputStatus::UInt8 begin
    InputAccepted
    MissingMeteorology
    MissingTime
    InvalidDewPoint
    InvalidDomain
end

"""Reason a numerical component solve did not produce an accepted root."""
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

"""Numerical acceptance criteria and iteration limit for a scalar root solve."""
struct SolverConfig{T<:AbstractFloat}
    root_tolerance_k::T
    residual_tolerance_k::T
    maximum_iterations::Int

    function SolverConfig{T}(
        root_tolerance_k::T,
        residual_tolerance_k::T,
        maximum_iterations::Int,
    ) where {T<:AbstractFloat}
        _require_finite_positive(root_tolerance_k, :root_tolerance_k)
        _require_finite_positive(residual_tolerance_k, :residual_tolerance_k)
        residual_tolerance_k <= T(0.01) ||
            throw(ArgumentError("residual_tolerance_k must not exceed 0.01 K"))
        maximum_iterations > 0 || throw(ArgumentError("maximum_iterations must be positive"))
        return new{T}(root_tolerance_k, residual_tolerance_k, maximum_iterations)
    end
end

function SolverConfig(
    ;
    root_tolerance_k::Real = 1e-6,
    residual_tolerance_k::Real = 1e-4,
    maximum_iterations::Integer = 128,
)
    float_type = _common_float_type(root_tolerance_k, residual_tolerance_k)
    return SolverConfig{float_type}(
        convert(float_type, root_tolerance_k),
        convert(float_type, residual_tolerance_k),
        Int(maximum_iterations),
    )
end

"""Physical constants, input policies, and solver settings for the Liljegren model."""
struct LiljegrenConfig{T<:AbstractFloat}
    solver::SolverConfig{T}
    dew_point_policy::DewPointPolicy
    dew_point_tolerance_c::T
    solar_time_mode::SolarTimeMode
    surface_albedo::T
    globe_diameter_m::T
    minimum_wind_speed_m_s::T

    function LiljegrenConfig{T}(
        solver::SolverConfig{T},
        dew_point_policy::DewPointPolicy,
        dew_point_tolerance_c::T,
        solar_time_mode::SolarTimeMode,
        surface_albedo::T,
        globe_diameter_m::T,
        minimum_wind_speed_m_s::T,
    ) where {T<:AbstractFloat}
        _require_finite_nonnegative(dew_point_tolerance_c, :dew_point_tolerance_c)
        isfinite(surface_albedo) && zero(T) <= surface_albedo <= one(T) ||
            throw(ArgumentError("surface_albedo must be finite and in [0, 1]"))
        _require_finite_positive(globe_diameter_m, :globe_diameter_m)
        _require_finite_nonnegative(minimum_wind_speed_m_s, :minimum_wind_speed_m_s)
        return new{T}(
            solver,
            dew_point_policy,
            dew_point_tolerance_c,
            solar_time_mode,
            surface_albedo,
            globe_diameter_m,
            minimum_wind_speed_m_s,
        )
    end
end

function LiljegrenConfig(
    ;
    solver::SolverConfig = SolverConfig(),
    dew_point_policy::DewPointPolicy = ClampDewPoint,
    dew_point_tolerance_c::Real = typeof(solver.root_tolerance_k)(1e-4),
    solar_time_mode::SolarTimeMode = TimestampSolarTime,
    surface_albedo::Real = typeof(solver.root_tolerance_k)(0.45),
    globe_diameter_m::Real = typeof(solver.root_tolerance_k)(0.0508),
    minimum_wind_speed_m_s::Real = typeof(solver.root_tolerance_k)(0.13),
)
    float_type = _common_float_type(
        solver.root_tolerance_k,
        dew_point_tolerance_c,
        surface_albedo,
        globe_diameter_m,
        minimum_wind_speed_m_s,
    )
    promoted_solver = SolverConfig{float_type}(
        convert(float_type, solver.root_tolerance_k),
        convert(float_type, solver.residual_tolerance_k),
        solver.maximum_iterations,
    )
    return LiljegrenConfig{float_type}(
        promoted_solver,
        dew_point_policy,
        convert(float_type, dew_point_tolerance_c),
        solar_time_mode,
        convert(float_type, surface_albedo),
        convert(float_type, globe_diameter_m),
        convert(float_type, minimum_wind_speed_m_s),
    )
end

"""Value-only outcome of a Liljegren WBGT calculation, in degrees Celsius."""
struct WBGTResult{T<:AbstractFloat}
    wbgt_c::Union{Missing,T}
    natural_wet_bulb_c::Union{Missing,T}
    globe_temperature_c::Union{Missing,T}

    function WBGTResult{T}(
        wbgt_c::Union{Missing,T},
        natural_wet_bulb_c::Union{Missing,T},
        globe_temperature_c::Union{Missing,T},
    ) where {T<:AbstractFloat}
        return new{T}(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
    end
end

function WBGTResult(
    wbgt_c::Union{Missing,Real},
    natural_wet_bulb_c::Union{Missing,Real},
    globe_temperature_c::Union{Missing,Real},
)
    float_type = _common_float_type(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
    return WBGTResult{float_type}(
        _convert_or_missing(float_type, wbgt_c),
        _convert_or_missing(float_type, natural_wet_bulb_c),
        _convert_or_missing(float_type, globe_temperature_c),
    )
end

"""Convergence trace for one component root solve."""
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

"""Value result plus explicit input-normalisation and solver diagnostics."""
struct DiagnosticWBGTResult{T<:AbstractFloat}
    result::WBGTResult{T}
    input_status::InputStatus
    dew_point_adjusted::Bool
    wind_speed_clamped::Bool
    solar_radiation_clamped::Bool
    solar_geometry_mismatch::Bool
    globe::SolverDiagnostics{T}
    natural_wet_bulb::SolverDiagnostics{T}

    function DiagnosticWBGTResult{T}(
        result::WBGTResult{T},
        input_status::InputStatus,
        dew_point_adjusted::Bool,
        wind_speed_clamped::Bool,
        solar_radiation_clamped::Bool,
        solar_geometry_mismatch::Bool,
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
            globe,
            natural_wet_bulb,
        )
    end
end

"""Structure-of-arrays value result for aligned batch calculations."""
struct WBGTBatchResult{T<:AbstractFloat,V<:AbstractVector{Union{Missing,T}}}
    wbgt_c::V
    natural_wet_bulb_c::V
    globe_temperature_c::V

    function WBGTBatchResult{T,V}(wbgt_c::V, natural_wet_bulb_c::V, globe_temperature_c::V) where {T<:AbstractFloat,V<:AbstractVector{Union{Missing,T}}}
        axes(wbgt_c) == axes(natural_wet_bulb_c) == axes(globe_temperature_c) ||
            throw(ArgumentError("batch result vectors must have identical axes"))
        return new{T,V}(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
    end
end

function WBGTBatchResult(wbgt_c::V, natural_wet_bulb_c::V, globe_temperature_c::V) where {T<:AbstractFloat,V<:AbstractVector{Union{Missing,T}}}
    return WBGTBatchResult{T,V}(wbgt_c, natural_wet_bulb_c, globe_temperature_c)
end
