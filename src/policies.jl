# Internal result of reconciling air and dew-point temperatures in degrees Celsius.
struct _DewPointResolution{T<:AbstractFloat}
    air_temperature_c::T
    dew_point_c::T
    adjusted::Bool
    status::InputStatus
end

# Apply the configured dew-point policy after finite-value validation.
function _resolve_dew_point(
    air_temperature_c::T,
    dew_point_c::T,
    policy::DewPointPolicy,
    tolerance_c::T,
) where {T<:AbstractFloat}
    dew_point_c <= air_temperature_c &&
        return _DewPointResolution(air_temperature_c, dew_point_c, false, InputAccepted)

    if dew_point_c - air_temperature_c <= tolerance_c
        return _DewPointResolution(air_temperature_c, air_temperature_c, true, InputAccepted)
    elseif policy === ClampDewPoint
        return _DewPointResolution(air_temperature_c, air_temperature_c, true, InputAccepted)
    elseif policy === SwapAirAndDewPoint
        return _DewPointResolution(dew_point_c, air_temperature_c, true, InputAccepted)
    end

    return _DewPointResolution(air_temperature_c, dew_point_c, false, InvalidDewPoint)
end
