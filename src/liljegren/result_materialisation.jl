@inline _component_or_missing(value::T, is_missing::Bool) where {T<:AbstractFloat} =
    is_missing ? missing : value

@inline function _wbgt_values(
    air_temperature_c::T,
    globe_temperature_c::Union{Missing,T},
    natural_wet_bulb_c::Union{Missing,T},
) where {T<:AbstractFloat}
    wbgt_c = if !ismissing(globe_temperature_c) && !ismissing(natural_wet_bulb_c)
        convert(T, 0.7) * natural_wet_bulb_c +
        convert(T, 0.2) * globe_temperature_c +
        convert(T, 0.1) * air_temperature_c
    else
        missing
    end
    return _LiljegrenValue{T}(
        ismissing(wbgt_c) ? zero(T) : wbgt_c,
        ismissing(natural_wet_bulb_c) ? zero(T) : natural_wet_bulb_c,
        ismissing(globe_temperature_c) ? zero(T) : globe_temperature_c,
        ismissing(wbgt_c),
        ismissing(natural_wet_bulb_c),
        ismissing(globe_temperature_c),
    )
end

@inline function _materialize_result(
    prepared::_PreparedMeteorology{T},
    data::_ScalarSolveData{T},
    config::LiljegrenConfig{T},
    ::_ValueMode,
) where {T<:AbstractFloat}
    globe_temperature_c = _accepted_component_value(data.globe, config.solver)
    natural_wet_bulb_c = _accepted_component_value(data.natural_wet_bulb, config.solver)
    return _wbgt_values(prepared.air_temperature_c, globe_temperature_c, natural_wet_bulb_c)
end

@inline function _materialize_result(
    prepared::_PreparedMeteorology{T},
    data::_ScalarSolveData{T},
    config::LiljegrenConfig{T},
    ::_DiagnosticMode,
) where {T<:AbstractFloat}
    values = _materialize_result(prepared, data, config, _ValueMode())
    result = _scalar_public_result(T, values, _ValueMode())
    globe = _solver_diagnostics(
        data.globe.location,
        data.globe.validation_residual_k,
        config.solver,
        data.globe.validation_evaluations,
    )
    natural_wet_bulb = _solver_diagnostics(
        data.natural_wet_bulb.location,
        data.natural_wet_bulb.validation_residual_k,
        config.solver,
        data.natural_wet_bulb.validation_evaluations,
    )
    return DiagnosticWBGTResult{T}(
        result,
        InputAccepted,
        prepared.dew_point_adjusted,
        prepared.wind_speed_clamped,
        prepared.solar_radiation_clamped,
        prepared.solar_geometry_mismatch,
        prepared.direct_solar_clipped,
        prepared.wind_height,
        prepared.irradiance,
        globe,
        natural_wet_bulb,
    )
end

@inline function _scalar_public_result(
    ::Type{T},
    values::_LiljegrenValue{T},
    ::_ValueMode,
) where {T<:AbstractFloat}
    return WBGTResult{T}(
        _component_or_missing(values.wbgt_c, values.wbgt_missing),
        _component_or_missing(values.natural_wet_bulb_c, values.natural_wet_bulb_missing),
        _component_or_missing(values.globe_temperature_c, values.globe_temperature_missing),
    )
end

@inline _scalar_public_result(::Type{T}, diagnostic::DiagnosticWBGTResult{T}, ::_DiagnosticMode) where {T<:AbstractFloat} = diagnostic
