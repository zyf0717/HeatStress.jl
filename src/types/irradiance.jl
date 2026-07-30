"""Policy used to resolve an underdetermined direct/diffuse irradiance split."""
abstract type RadiationPartitionPolicy end

"""
    FixedDirectFraction(value=0.8)

Use an explicit direct-horizontal/GHI fraction. `value` may be a scalar or,
for batch calls, a row-aligned vector. Values must be finite and in `[0, 1]`.
"""
struct FixedDirectFraction{V} <: RadiationPartitionPolicy
    value::V
end

function FixedDirectFraction(value::Real = 0.8)
    fraction = float(value)
    isfinite(fraction) && zero(fraction) <= fraction <= one(fraction) ||
        throw(ArgumentError("fixed direct fraction must be finite and in [0, 1]"))
    return FixedDirectFraction{typeof(fraction)}(fraction)
end

function FixedDirectFraction(value::AbstractVector)
    for fraction in value
        fraction isa Real && isfinite(fraction) && 0 <= fraction <= 1 ||
            throw(ArgumentError(
                "fixed direct-fraction values must be finite Reals in [0, 1]",
            ))
    end
    return FixedDirectFraction{typeof(value)}(value)
end

"""
    LiljegrenClearnessFraction()

Estimate the direct-horizontal/GHI fraction from the Liljegren clearness-index
relation. Supplied GHI is never capped; only the empirical clearness argument
is bounded.
"""
struct LiljegrenClearnessFraction <: RadiationPartitionPolicy end

"""Resolved irradiance state and reconciliation evidence for one Liljegren row."""
struct IrradianceDiagnostics{T<:AbstractFloat}
    ghi_w_m2::Union{Missing,T}
    dni_w_m2::Union{Missing,T}
    dhi_w_m2::Union{Missing,T}
    direct_fraction::Union{Missing,T}
    clear_sky_ghi_w_m2::Union{Missing,T}
    ghi_supplied::Bool
    dni_supplied::Bool
    dhi_supplied::Bool
    ghi_estimated::Bool
    dni_estimated::Bool
    dhi_estimated::Bool
    ghi_clamped::Bool
    dni_clamped::Bool
    dhi_clamped::Bool
    derived_component_adjusted::Bool
    closure_residual_w_m2::Union{Missing,T}
    closure_tolerance_w_m2::Union{Missing,T}
    closure_mismatch::Bool
    partition_policy::Symbol

    function IrradianceDiagnostics{T}(
        ghi_w_m2::Union{Missing,T},
        dni_w_m2::Union{Missing,T},
        dhi_w_m2::Union{Missing,T},
        direct_fraction::Union{Missing,T},
        clear_sky_ghi_w_m2::Union{Missing,T},
        ghi_supplied::Bool,
        dni_supplied::Bool,
        dhi_supplied::Bool,
        ghi_estimated::Bool,
        dni_estimated::Bool,
        dhi_estimated::Bool,
        ghi_clamped::Bool,
        dni_clamped::Bool,
        dhi_clamped::Bool,
        derived_component_adjusted::Bool,
        closure_residual_w_m2::Union{Missing,T},
        closure_tolerance_w_m2::Union{Missing,T},
        closure_mismatch::Bool,
        partition_policy::Symbol,
    ) where {T<:AbstractFloat}
        return new{T}(
            ghi_w_m2,
            dni_w_m2,
            dhi_w_m2,
            direct_fraction,
            clear_sky_ghi_w_m2,
            ghi_supplied,
            dni_supplied,
            dhi_supplied,
            ghi_estimated,
            dni_estimated,
            dhi_estimated,
            ghi_clamped,
            dni_clamped,
            dhi_clamped,
            derived_component_adjusted,
            closure_residual_w_m2,
            closure_tolerance_w_m2,
            closure_mismatch,
            partition_policy,
        )
    end
end

"""Structure-of-arrays irradiance diagnostics for aligned batch rows."""
struct IrradianceDiagnosticsBatch{T<:AbstractFloat}
    ghi_w_m2::Vector{Union{Missing,T}}
    dni_w_m2::Vector{Union{Missing,T}}
    dhi_w_m2::Vector{Union{Missing,T}}
    direct_fraction::Vector{Union{Missing,T}}
    clear_sky_ghi_w_m2::Vector{Union{Missing,T}}
    ghi_supplied::Vector{Bool}
    dni_supplied::Vector{Bool}
    dhi_supplied::Vector{Bool}
    ghi_estimated::Vector{Bool}
    dni_estimated::Vector{Bool}
    dhi_estimated::Vector{Bool}
    ghi_clamped::Vector{Bool}
    dni_clamped::Vector{Bool}
    dhi_clamped::Vector{Bool}
    derived_component_adjusted::Vector{Bool}
    closure_residual_w_m2::Vector{Union{Missing,T}}
    closure_tolerance_w_m2::Vector{Union{Missing,T}}
    closure_mismatch::Vector{Bool}
    partition_policy::Vector{Symbol}

    function IrradianceDiagnosticsBatch{T}(
        ghi_w_m2::Vector{Union{Missing,T}},
        dni_w_m2::Vector{Union{Missing,T}},
        dhi_w_m2::Vector{Union{Missing,T}},
        direct_fraction::Vector{Union{Missing,T}},
        clear_sky_ghi_w_m2::Vector{Union{Missing,T}},
        ghi_supplied::Vector{Bool},
        dni_supplied::Vector{Bool},
        dhi_supplied::Vector{Bool},
        ghi_estimated::Vector{Bool},
        dni_estimated::Vector{Bool},
        dhi_estimated::Vector{Bool},
        ghi_clamped::Vector{Bool},
        dni_clamped::Vector{Bool},
        dhi_clamped::Vector{Bool},
        derived_component_adjusted::Vector{Bool},
        closure_residual_w_m2::Vector{Union{Missing,T}},
        closure_tolerance_w_m2::Vector{Union{Missing,T}},
        closure_mismatch::Vector{Bool},
        partition_policy::Vector{Symbol},
    ) where {T<:AbstractFloat}
        rows = length(ghi_w_m2)
        all(length(values) == rows for values in (
            dni_w_m2,
            dhi_w_m2,
            direct_fraction,
            clear_sky_ghi_w_m2,
            ghi_supplied,
            dni_supplied,
            dhi_supplied,
            ghi_estimated,
            dni_estimated,
            dhi_estimated,
            ghi_clamped,
            dni_clamped,
            dhi_clamped,
            derived_component_adjusted,
            closure_residual_w_m2,
            closure_tolerance_w_m2,
            closure_mismatch,
            partition_policy,
        )) || throw(ArgumentError(
            "batch irradiance diagnostic vectors must have identical lengths",
        ))
        return new{T}(
            ghi_w_m2,
            dni_w_m2,
            dhi_w_m2,
            direct_fraction,
            clear_sky_ghi_w_m2,
            ghi_supplied,
            dni_supplied,
            dhi_supplied,
            ghi_estimated,
            dni_estimated,
            dhi_estimated,
            ghi_clamped,
            dni_clamped,
            dhi_clamped,
            derived_component_adjusted,
            closure_residual_w_m2,
            closure_tolerance_w_m2,
            closure_mismatch,
            partition_policy,
        )
    end
end
