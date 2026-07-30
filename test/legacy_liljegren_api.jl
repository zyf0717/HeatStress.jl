_compat_partition(value) = FixedDirectFraction{typeof(value)}(value)

function _compat_diagnose_liljegren(air, dew, wind, ghi, time, longitude, latitude;
                                    direct_fraction, kwargs...)
    return diagnose_liljegren(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _compat_partition(direct_fraction), kwargs...,
    )
end

function _compat_liljegren_wbgt_batch(air, dew, wind, ghi, time, longitude, latitude;
                                      direct_fraction, kwargs...)
    return liljegren_wbgt_batch(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _compat_partition(direct_fraction), kwargs...,
    )
end

function _compat_diagnose_liljegren_batch(
    air, dew, wind, ghi, time, longitude, latitude;
    direct_fraction, kwargs...,
)
    return diagnose_liljegren_batch(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _compat_partition(direct_fraction), kwargs...,
    )
end

function _compat_liljegren_wbgt!(
    wbgt, wet, globe, air, dew, wind, ghi, time, longitude, latitude;
    direct_fraction, kwargs...,
)
    return liljegren_wbgt!(
        wbgt, wet, globe, air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _compat_partition(direct_fraction), kwargs...,
    )
end
