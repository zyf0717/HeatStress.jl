abstract type _ScalarResultMode end
struct _ValueMode <: _ScalarResultMode end
struct _DiagnosticMode <: _ScalarResultMode end

"""Shared component-solve state; diagnostics are materialized only on demand."""
struct _ScalarSolveData{T<:AbstractFloat}
    globe::_ValidatedComponentSolve{T}
    natural_wet_bulb::_ValidatedComponentSolve{T}
end

"""Internal isbits value-only row outcome; avoids public result materialisation in batch loops."""
struct _LiljegrenValue{T<:AbstractFloat}
    wbgt_c::T
    natural_wet_bulb_c::T
    globe_temperature_c::T
    wbgt_missing::Bool
    natural_wet_bulb_missing::Bool
    globe_temperature_missing::Bool
end

function _input_failure_diagnostic(
    status::InputStatus,
    config::LiljegrenConfig{T},
    irradiance::IrradianceDiagnostics{T} = _empty_irradiance_diagnostics(T),
) where {T<:AbstractFloat}
    diagnostics = _not_attempted_diagnostics(config.solver)
    return DiagnosticWBGTResult{T}(
        WBGTResult{T}(missing, missing, missing),
        status,
        false,
        false,
        false,
        false,
        false,
        _empty_wind_height_diagnostics(T),
        irradiance,
        diagnostics,
        diagnostics,
    )
end

@inline _input_failure_result(::Type{T}, ::_ValueMode, ::InputStatus, ::LiljegrenConfig{T}) where {T<:AbstractFloat} =
    _LiljegrenValue{T}(zero(T), zero(T), zero(T), true, true, true)

@inline _input_failure_result(::Type{T}, ::_DiagnosticMode, status::InputStatus, config::LiljegrenConfig{T}) where {T<:AbstractFloat} =
    _input_failure_diagnostic(status, config)

@inline _input_failure_result(
    ::Type{T},
    ::_ValueMode,
    ::InputStatus,
    ::LiljegrenConfig{T},
    ::IrradianceDiagnostics{T},
) where {T<:AbstractFloat} =
    _LiljegrenValue{T}(zero(T), zero(T), zero(T), true, true, true)

@inline _input_failure_result(
    ::Type{T},
    ::_DiagnosticMode,
    status::InputStatus,
    config::LiljegrenConfig{T},
    irradiance::IrradianceDiagnostics{T},
) where {T<:AbstractFloat} =
    _input_failure_diagnostic(status, config, irradiance)

@inline _input_failure_result(
    ::Type{T},
    ::_ValueMode,
    ::InputStatus,
    ::LiljegrenConfig{T},
    ::IrradianceDiagnostics{T},
    ::WindHeightDiagnostics{T},
) where {T<:AbstractFloat} =
    _LiljegrenValue{T}(zero(T), zero(T), zero(T), true, true, true)

@inline function _input_failure_result(
    ::Type{T},
    ::_DiagnosticMode,
    status::InputStatus,
    config::LiljegrenConfig{T},
    irradiance::IrradianceDiagnostics{T},
    wind_height::WindHeightDiagnostics{T},
) where {T<:AbstractFloat}
    diagnostics = _not_attempted_diagnostics(config.solver)
    return DiagnosticWBGTResult{T}(
        WBGTResult{T}(missing, missing, missing),
        status,
        false,
        false,
        false,
        false,
        false,
        wind_height,
        irradiance,
        diagnostics,
        diagnostics,
    )
end
