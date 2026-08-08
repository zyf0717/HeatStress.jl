function _rcc_batch_float_type(
    air,
    humidity,
    wind,
    longitude,
    latitude,
    ghi,
    pressure,
    partition::RadiationPartitionPolicy,
)
    T = promote_type(
        _batch_value_type(typeof(air)),
        _batch_value_type(typeof(humidity)),
        _batch_value_type(typeof(wind)),
        _batch_value_type(typeof(longitude)),
        _batch_value_type(typeof(latitude)),
        _batch_value_type(typeof(ghi)),
        _batch_value_type(typeof(pressure)),
        _batch_value_type(typeof(_partition_values(partition))),
    )
    return T === Union{} ? Float64 : T
end

function _prepare_rcc_batch(
    combination::_RCCWBGTCombination,
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude,
    ghi_w_m2,
    pressure_hpa,
    partition::RadiationPartitionPolicy,
    threaded::Bool,
)
    threaded && throw(ArgumentError(
        "threaded RCC batches are not enabled; profiling is required before opt-in",
    ))
    rows = _batch_rows(air, humidity, wind, time)
    _validate_numeric_vector(air, rows, :air_temperature_c; allow_missing = true)
    _validate_numeric_vector(
        humidity,
        rows,
        :relative_humidity_percent;
        allow_missing = true,
    )
    _validate_numeric_vector(wind, rows, :wind_speed_m_s; allow_missing = true)
    _validate_time_vector(time, rows, :time)
    _validate_location_argument(longitude, rows, :longitude_deg)
    _validate_location_argument(latitude, rows, :latitude_deg)
    _validate_optional_numeric_argument(ghi_w_m2, rows, :ghi_w_m2)
    _validate_optional_numeric_argument(pressure_hpa, rows, :pressure_hpa)
    _validate_partition(partition, rows)
    T = _rcc_batch_float_type(
        air,
        humidity,
        wind,
        longitude,
        latitude,
        ghi_w_m2,
        pressure_hpa,
        partition,
    )

    # Domain and geometry validation precedes all preallocated output writes.
    for row in 1:rows
        row_air = _at(air, row)
        row_humidity = _at(humidity, row)
        row_wind = _at(wind, row)
        row_ghi = _at(ghi_w_m2, row)
        row_pressure = _at(pressure_hpa, row)
        row_longitude = _at(longitude, row)
        row_latitude = _at(latitude, row)
        _validate_longitude_deg(row_longitude)
        _validate_latitude_deg(row_latitude)
        if !any(ismissing, (row_air, row_humidity, row_wind, row_ghi))
            air_t = convert(T, row_air)
            humidity_t = convert(T, row_humidity)
            wind_t = convert(T, row_wind)
            ghi_t = convert(T, row_ghi)
            _rcc_validate_air_temperature(air_t)
            _rcc_validate_relative_humidity(humidity_t)
            _rcc_validate_wind(
                wind_t;
                positive = _rcc_requires_positive_wind(combination),
            )
            _rcc_validate_ghi(ghi_t)
            ismissing(row_pressure) || _rcc_validate_pressure(convert(T, row_pressure))
            row_time = _at(time, row)
            if !ismissing(row_time) && ghi_t > zero(T)
                zenith = solar_zenith(row_time, row_longitude, row_latitude)
                zenith < 90 || throw(ArgumentError(
                    "positive ghi_w_m2 requires solar zenith below 90 degrees at row $row",
                ))
            end
        end
    end
    return rows, T
end

function _execute_rcc_batch!(
    combination::_RCCWBGTCombination,
    rows::Int,
    ::Type{T},
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air,
    humidity,
    wind,
    time,
    longitude,
    latitude,
    ghi_w_m2,
    pressure_hpa,
    partition,
) where {T<:AbstractFloat}
    for row in 1:rows
        result = _rcc_row_from_time(
            combination,
            _at(air, row),
            _at(humidity, row),
            _at(wind, row),
            _at(time, row),
            _at(longitude, row),
            _at(latitude, row),
            _at(ghi_w_m2, row),
            _at(pressure_hpa, row),
            _partition_at(partition, row),
            T,
        )
        output_index = firstindex(wbgt_out) + row - 1
        @inbounds wbgt_out[output_index] = result.wbgt_c
        @inbounds wet_out[firstindex(wet_out) + row - 1] = result.natural_wet_bulb_c
        @inbounds globe_out[firstindex(globe_out) + row - 1] = result.globe_temperature_c
    end
    return WBGTBatchResult{T}(wbgt_out, wet_out, globe_out)
end

function _rcc_wbgt!(
    combination::_RCCWBGTCombination,
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
    threaded::Bool = false,
)
    rows, T = _prepare_rcc_batch(
        combination,
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude,
        ghi_w_m2,
        pressure_hpa,
        partition,
        threaded,
    )
    _validate_batch_outputs(rows, T, wbgt_out, wet_out, globe_out)
    _validate_batch_aliases(
        (wbgt_out, wet_out, globe_out),
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude,
        ghi_w_m2,
        pressure_hpa,
        _partition_values(partition),
    )
    return _execute_rcc_batch!(
        combination,
        rows,
        T,
        wbgt_out,
        wet_out,
        globe_out,
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude,
        ghi_w_m2,
        pressure_hpa,
        partition,
    )
end

function _rcc_wbgt_batch(
    combination::_RCCWBGTCombination,
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
    threaded::Bool = false,
)
    rows, T = _prepare_rcc_batch(
        combination,
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude,
        ghi_w_m2,
        pressure_hpa,
        partition,
        threaded,
    )
    wbgt = Vector{Union{Missing,T}}(undef, rows)
    wet = similar(wbgt)
    globe = similar(wbgt)
    return _execute_rcc_batch!(
        combination,
        rows,
        T,
        wbgt,
        wet,
        globe,
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude,
        ghi_w_m2,
        pressure_hpa,
        partition,
    )
end

"""Mutate aligned output vectors with RCCD167L values."""
function rccd167l_wbgt!(
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
    threaded::Bool = false,
)
    return _rcc_wbgt!(
        _RCCD167LCombination(),
        wbgt_out,
        wet_out,
        globe_out,
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude;
        ghi_w_m2,
        pressure_hpa,
        partition,
        threaded,
    )
end

"""Return aligned RCCD167L WBGT and component vectors."""
function rccd167l_wbgt_batch(
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
    threaded::Bool = false,
)
    return _rcc_wbgt_batch(
        _RCCD167LCombination(),
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude;
        ghi_w_m2,
        pressure_hpa,
        partition,
        threaded,
    )
end

"""Mutate aligned output vectors with RCC Table 5 NWS-combination values."""
function rcc_nws_wbgt!(
    wbgt_out::AbstractVector,
    wet_out::AbstractVector,
    globe_out::AbstractVector,
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
    threaded::Bool = false,
)
    return _rcc_wbgt!(
        _RCCNWSCombination(),
        wbgt_out,
        wet_out,
        globe_out,
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude;
        ghi_w_m2,
        pressure_hpa,
        partition,
        threaded,
    )
end

"""Return aligned RCC Table 5 NWS-combination WBGT and component vectors."""
function rcc_nws_wbgt_batch(
    air::AbstractVector,
    humidity::AbstractVector,
    wind::AbstractVector,
    time::AbstractVector,
    longitude,
    latitude;
    ghi_w_m2,
    pressure_hpa = DEFAULT_PRESSURE_HPA,
    partition::RadiationPartitionPolicy = LiljegrenClearnessFraction(),
    threaded::Bool = false,
)
    return _rcc_wbgt_batch(
        _RCCNWSCombination(),
        air,
        humidity,
        wind,
        time,
        longitude,
        latitude;
        ghi_w_m2,
        pressure_hpa,
        partition,
        threaded,
    )
end
