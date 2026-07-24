"""Numerical acceptance criteria: root/residual tolerances are K; iterations are unitless."""
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

"""Liljegren settings: dew-point tolerance is °C, globe diameter is m, and minimum wind is m/s."""
struct LiljegrenConfig{T<:AbstractFloat}
    solver::SolverConfig{T}
    dew_point_policy::DewPointPolicy
    dew_point_tolerance_c::T
    surface_albedo::T
    globe_diameter_m::T
    minimum_wind_speed_m_s::T

    function LiljegrenConfig{T}(
        solver::SolverConfig{T},
        dew_point_policy::DewPointPolicy,
        dew_point_tolerance_c::T,
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
    surface_albedo::Real = typeof(solver.root_tolerance_k)(DEFAULT_SURFACE_ALBEDO),
    globe_diameter_m::Real = typeof(solver.root_tolerance_k)(DEFAULT_GLOBE_DIAMETER_M),
    minimum_wind_speed_m_s::Real = typeof(solver.root_tolerance_k)(DEFAULT_MINIMUM_WIND_SPEED_M_S),
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
        convert(float_type, surface_albedo),
        convert(float_type, globe_diameter_m),
        convert(float_type, minimum_wind_speed_m_s),
    )
end
