struct _ResolvedIrradiance{T<:AbstractFloat}
    ghi_w_m2::T
    dni_w_m2::Union{Missing,T}
    dhi_w_m2::T
    direct_fraction::T
    geometry_mismatch::Bool
    diagnostics::IrradianceDiagnostics{T}
end

struct _IrradianceResolutionFailure{T<:AbstractFloat}
    diagnostics::IrradianceDiagnostics{T}
end

@inline _partition_symbol(::FixedDirectFraction) = :fixed
@inline _partition_symbol(::LiljegrenClearnessFraction) = :liljegren_clearness

function _empty_irradiance_diagnostics(
    ::Type{T},
    policy::RadiationPartitionPolicy = FixedDirectFraction(),
) where {T<:AbstractFloat}
    return IrradianceDiagnostics{T}(
        missing, missing, missing, missing, missing,
        false, false, false, false, false, false,
        false, false, false, false,
        missing, missing, false, _partition_symbol(policy),
    )
end

@inline function _normalise_irradiance_component(value, ::Type{T}) where {T<:AbstractFloat}
    value isa Union{Nothing,Missing} && return (false, zero(T), false, true)
    value isa Real || return (false, zero(T), false, false)
    converted = convert(T, value)
    isfinite(converted) || return (true, converted, false, false)
    clamped = converted < zero(T)
    return (true, max(converted, zero(T)), clamped, true)
end

@inline function _clear_sky_ghi(cos_zenith::T) where {T<:AbstractFloat}
    return max(
        zero(T),
        convert(T, KASTEN_CZEPLAK_GHI_SLOPE_W_M2) * max(zero(T), cos_zenith) -
        convert(T, KASTEN_CZEPLAK_GHI_INTERCEPT_W_M2),
    )
end

@inline function _extraterrestrial_horizontal_irradiance(
    utc_time::DateTime,
    cos_zenith::T,
) where {T<:AbstractFloat}
    day_angle = convert(T, 2π * Dates.dayofyear(utc_time) / 365)
    inverse_relative_distance = one(T) + convert(T, 0.033) * cos(day_angle)
    return convert(T, LILJEGREN_SOLAR_CONSTANT_W_M2) *
           inverse_relative_distance * max(zero(T), cos_zenith)
end

function _partition_fraction(
    policy::FixedDirectFraction,
    ::DateTime,
    ::T,
    ::T,
    ::Type{T},
) where {T<:AbstractFloat}
    policy.value isa Real || return missing
    fraction = convert(T, policy.value)
    isfinite(fraction) && zero(T) <= fraction <= one(T) || return missing
    return fraction
end

function _partition_fraction(
    ::LiljegrenClearnessFraction,
    utc_time::DateTime,
    ghi_w_m2::T,
    cos_zenith::T,
    ::Type{T},
) where {T<:AbstractFloat}
    ghi_w_m2 > zero(T) || return zero(T)
    toa = _extraterrestrial_horizontal_irradiance(utc_time, cos_zenith)
    toa > zero(T) || return zero(T)
    clearness = min(
        ghi_w_m2 / toa,
        convert(T, LILJEGREN_CLEARNESS_MAX),
    )
    clearness > zero(T) || return zero(T)
    fraction = exp(
        convert(T, 3) - convert(T, 1.34) * clearness -
        convert(T, 1.65) / clearness,
    )
    return clamp(fraction, zero(T), convert(T, LILJEGREN_DIRECT_FRACTION_MAX))
end

@inline function _dni_from_bhi(bhi::T, cos_zenith::T) where {T<:AbstractFloat}
    direct_cutoff = sin(convert(T, MINIMUM_DIRECT_SOLAR_ELEVATION_RAD))
    bhi > zero(T) || return zero(T)
    cos_zenith >= direct_cutoff || return missing
    return bhi / cos_zenith
end

function _irradiance_diagnostics(
    ::Type{T};
    ghi = missing,
    dni = missing,
    dhi = missing,
    fraction = missing,
    clear_sky = missing,
    supplied = (false, false, false),
    estimated = (false, false, false),
    clamped = (false, false, false),
    adjusted = false,
    closure_residual = missing,
    closure_tolerance = missing,
    closure_mismatch = false,
    policy::RadiationPartitionPolicy,
) where {T<:AbstractFloat}
    cv(value) = ismissing(value) ? missing : convert(T, value)
    return IrradianceDiagnostics{T}(
        cv(ghi), cv(dni), cv(dhi), cv(fraction), cv(clear_sky),
        supplied..., estimated..., clamped..., adjusted,
        cv(closure_residual), cv(closure_tolerance), closure_mismatch,
        _partition_symbol(policy),
    )
end

function _resolve_irradiance(
    ghi_input,
    dni_input,
    dhi_input,
    policy::RadiationPartitionPolicy,
    utc_time::DateTime,
    zenith_rad::T,
    config::LiljegrenConfig{T},
) where {T<:AbstractFloat}
    ghi_supplied, ghi, ghi_clamped, ghi_valid =
        _normalise_irradiance_component(ghi_input, T)
    dni_supplied, dni, dni_clamped, dni_valid =
        _normalise_irradiance_component(dni_input, T)
    dhi_supplied, dhi, dhi_clamped, dhi_valid =
        _normalise_irradiance_component(dhi_input, T)
    supplied = (ghi_supplied, dni_supplied, dhi_supplied)
    clamped = (ghi_clamped, dni_clamped, dhi_clamped)

    if !(ghi_valid && dni_valid && dhi_valid)
        diagnostics = _irradiance_diagnostics(
            T;
            ghi = ghi_supplied ? ghi : missing,
            dni = dni_supplied ? dni : missing,
            dhi = dhi_supplied ? dhi : missing,
            supplied,
            clamped,
            policy,
        )
        return _IrradianceResolutionFailure{T}(diagnostics)
    end

    cos_zenith = cos(zenith_rad)
    below_horizon = zenith_rad >= convert(T, π / 2)
    positive_supplied =
        (ghi_supplied && ghi > zero(T)) ||
        (dni_supplied && dni > zero(T)) ||
        (dhi_supplied && dhi > zero(T))
    if below_horizon
        diagnostics = _irradiance_diagnostics(
            T;
            ghi = zero(T), dni = zero(T), dhi = zero(T), fraction = zero(T),
            clear_sky = zero(T), supplied, clamped, policy,
        )
        return _ResolvedIrradiance{T}(
            zero(T), zero(T), zero(T), zero(T), positive_supplied, diagnostics,
        )
    end

    clear_sky = _clear_sky_ghi(cos_zenith)
    toa = _extraterrestrial_horizontal_irradiance(utc_time, cos_zenith)
    closure_tolerance = max(
        config.irradiance_closure_atol_w_m2,
        config.irradiance_closure_kt_tolerance * toa,
    )
    supplied_count = ghi_supplied + dni_supplied + dhi_supplied
    estimated = (false, false, false)
    adjusted = false
    closure_residual = missing
    closure_mismatch = false
    bhi = dni * max(zero(T), cos_zenith)

    if supplied_count == 3
        closure_residual = ghi - dhi - bhi
        closure_mismatch = abs(closure_residual) > closure_tolerance
    elseif ghi_supplied && dni_supplied
        derived = ghi - bhi
        if derived < -closure_tolerance
            closure_residual = derived
            closure_mismatch = true
        else
            adjusted = derived < zero(T)
            dhi = max(zero(T), derived)
            estimated = (false, false, true)
        end
    elseif ghi_supplied && dhi_supplied
        derived = ghi - dhi
        if derived < -closure_tolerance
            closure_residual = derived
            closure_mismatch = true
        else
            adjusted = derived < zero(T)
            bhi = max(zero(T), derived)
            dni = _dni_from_bhi(bhi, cos_zenith)
            estimated = (false, true, false)
        end
    elseif dni_supplied && dhi_supplied
        ghi = bhi + dhi
        estimated = (true, false, false)
    elseif ghi_supplied
        fraction = _partition_fraction(policy, utc_time, ghi, cos_zenith, T)
        if ismissing(fraction)
            diagnostics = _irradiance_diagnostics(
                T; ghi, supplied, clamped, clear_sky, policy,
            )
            return _IrradianceResolutionFailure{T}(diagnostics)
        end
        bhi = fraction * ghi
        dhi = ghi - bhi
        dni = _dni_from_bhi(bhi, cos_zenith)
        estimated = (false, true, true)
    elseif dni_supplied
        if policy isa FixedDirectFraction
            fraction = _partition_fraction(policy, utc_time, zero(T), cos_zenith, T)
            if ismissing(fraction) || (fraction == zero(T) && bhi > zero(T))
                diagnostics = _irradiance_diagnostics(
                    T; dni, supplied, clamped, clear_sky, policy,
                )
                return _IrradianceResolutionFailure{T}(diagnostics)
            end
            ghi = fraction == zero(T) ? zero(T) : bhi / fraction
            dhi = max(zero(T), ghi - bhi)
        else
            clear_fraction = _partition_fraction(policy, utc_time, clear_sky, cos_zenith, T)
            dhi = (one(T) - clear_fraction) * clear_sky
            ghi = bhi + dhi
        end
        estimated = (true, false, true)
    elseif dhi_supplied
        if policy isa FixedDirectFraction
            fraction = _partition_fraction(policy, utc_time, zero(T), cos_zenith, T)
            if ismissing(fraction) || (fraction == one(T) && dhi > zero(T))
                diagnostics = _irradiance_diagnostics(
                    T; dhi, supplied, clamped, clear_sky, policy,
                )
                return _IrradianceResolutionFailure{T}(diagnostics)
            end
            ghi = fraction == one(T) ? zero(T) : dhi / (one(T) - fraction)
            bhi = fraction * ghi
        else
            clear_fraction = _partition_fraction(policy, utc_time, clear_sky, cos_zenith, T)
            bhi = clear_fraction * clear_sky
            ghi = dhi + bhi
        end
        dni = _dni_from_bhi(bhi, cos_zenith)
        estimated = (true, true, false)
    else
        ghi = clear_sky
        fraction = _partition_fraction(policy, utc_time, ghi, cos_zenith, T)
        if ismissing(fraction)
            diagnostics = _irradiance_diagnostics(T; clear_sky, policy)
            return _IrradianceResolutionFailure{T}(diagnostics)
        end
        bhi = fraction * ghi
        dhi = ghi - bhi
        dni = _dni_from_bhi(bhi, cos_zenith)
        estimated = (true, true, true)
    end

    if closure_mismatch
        diagnostics = _irradiance_diagnostics(
            T;
            ghi, dni, dhi, clear_sky, supplied, estimated,
            clamped, adjusted, closure_residual, closure_tolerance,
            closure_mismatch = true, policy,
        )
        return _IrradianceResolutionFailure{T}(diagnostics)
    end

    fraction = ghi > zero(T) ? clamp(bhi / ghi, zero(T), one(T)) : zero(T)
    diagnostics = _irradiance_diagnostics(
        T;
        ghi, dni, dhi, fraction, clear_sky, supplied,
        estimated, clamped, adjusted,
        closure_residual, closure_tolerance, policy,
    )
    return _ResolvedIrradiance{T}(
        ghi, dni, dhi, fraction, false, diagnostics,
    )
end
