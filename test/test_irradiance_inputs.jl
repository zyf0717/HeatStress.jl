using Dates: DateTime, Hour
using OffsetArrays
using Test

const _IRRADIANCE_TIME = DateTime(2024, 6, 21, 12)
const _IRRADIANCE_LONGITUDE = 0.0
const _IRRADIANCE_LATITUDE = 0.0

function _irradiance_call(; ghi = nothing, dni = nothing, dhi = nothing,
                          partition = FixedDirectFraction(0.8))
    return diagnose_liljegren(
        30.0, 20.0, 1.0,
        _IRRADIANCE_TIME, _IRRADIANCE_LONGITUDE, _IRRADIANCE_LATITUDE;
        ghi_w_m2 = ghi, dni_w_m2 = dni, dhi_w_m2 = dhi, partition,
    )
end

@testset "irradiance component inputs" begin
    zenith = deg2rad(solar_zenith(
        _IRRADIANCE_TIME, _IRRADIANCE_LONGITUDE, _IRRADIANCE_LATITUDE,
    ))
    cosine = cos(zenith)
    ghi = 800.0
    direct_horizontal = 0.8 * ghi
    dhi = ghi - direct_horizontal
    dni = direct_horizontal / cosine

    @testset "all eight presence combinations" begin
        cases = (
            (ghi, dni, dhi),
            (ghi, dni, nothing),
            (ghi, nothing, dhi),
            (nothing, dni, dhi),
            (ghi, nothing, nothing),
            (nothing, dni, nothing),
            (nothing, nothing, dhi),
            (nothing, nothing, nothing),
        )
        supplied_flags = (
            (true, true, true),
            (true, true, false),
            (true, false, true),
            (false, true, true),
            (true, false, false),
            (false, true, false),
            (false, false, true),
            (false, false, false),
        )
        for (inputs, supplied) in zip(cases, supplied_flags)
            diagnostic = _irradiance_call(
                ghi = inputs[1], dni = inputs[2], dhi = inputs[3],
            )
            @test diagnostic.input_status === InputAccepted
            @test diagnostic.irradiance.ghi_supplied === supplied[1]
            @test diagnostic.irradiance.dni_supplied === supplied[2]
            @test diagnostic.irradiance.dhi_supplied === supplied[3]
            @test diagnostic.irradiance.partition_policy === :fixed
            @test diagnostic.irradiance.ghi_w_m2 ≈
                  (all(!, supplied) ? diagnostic.irradiance.clear_sky_ghi_w_m2 : ghi)
            @test diagnostic.irradiance.direct_fraction ≈ 0.8
            @test diagnostic.irradiance.ghi_w_m2 ≈
                  diagnostic.irradiance.dhi_w_m2 +
                  diagnostic.irradiance.dni_w_m2 * cosine
        end
    end

    @testset "direct fraction and clearness policies" begin
        from_ghi = _irradiance_call(ghi = ghi)
        @test from_ghi.irradiance.dhi_w_m2 ≈ 0.2 * ghi
        @test from_ghi.irradiance.dni_w_m2 * cosine ≈ 0.8 * ghi

        measured_partition = _irradiance_call(ghi = ghi, dhi = 0.35 * ghi)
        @test measured_partition.irradiance.direct_fraction ≈ 0.65

        high_ghi = 2_000.0
        clearness = _irradiance_call(
            ghi = high_ghi,
            partition = LiljegrenClearnessFraction(),
        )
        @test clearness.input_status === InputAccepted
        @test clearness.irradiance.ghi_w_m2 == high_ghi
        @test 0.0 <= clearness.irradiance.direct_fraction <= 1.0
        @test clearness.irradiance.partition_policy === :liljegren_clearness

        test_cosine = 0.5
        toa = HeatStress._extraterrestrial_horizontal_irradiance(
            _IRRADIANCE_TIME,
            test_cosine,
        )
        uncapped_clearness = 0.9
        uncapped_fraction = HeatStress._partition_fraction(
            LiljegrenClearnessFraction(),
            _IRRADIANCE_TIME,
            uncapped_clearness * toa,
            test_cosine,
            Float64,
        )
        @test uncapped_fraction ≈ exp(
            3 - 1.34 * uncapped_clearness - 1.65 / uncapped_clearness,
        )
        @test uncapped_fraction > 0.9
        @test HeatStress._partition_fraction(
            LiljegrenClearnessFraction(),
            _IRRADIANCE_TIME,
            1.1 * toa,
            test_cosine,
            Float64,
        ) == 1.0

        clear = _irradiance_call()
        @test clear.irradiance.ghi_w_m2 ≈ max(0.0, 910.0 * cosine - 30.0)
        @test clear.irradiance.ghi_estimated
        @test clear.irradiance.dni_estimated
        @test clear.irradiance.dhi_estimated
    end

    @testset "closure, normalisation, and horizon handling" begin
        inconsistent = _irradiance_call(ghi = ghi, dni = dni, dhi = 400.0)
        @test inconsistent.input_status === InvalidDomain
        @test inconsistent.irradiance.closure_mismatch
        @test inconsistent.globe.reason === NotAttempted
        @test inconsistent.natural_wet_bulb.reason === NotAttempted

        adjusted = _irradiance_call(ghi = ghi, dhi = ghi + 5.0)
        @test adjusted.input_status === InputAccepted
        @test adjusted.irradiance.derived_component_adjusted
        @test adjusted.irradiance.dni_w_m2 == 0.0

        clamped = _irradiance_call(ghi = -1.0)
        @test clamped.input_status === InputAccepted
        @test clamped.solar_radiation_clamped
        @test clamped.irradiance.ghi_clamped
        @test clamped.irradiance.ghi_w_m2 == 0.0

        @test _irradiance_call(dni = 1.0, partition = FixedDirectFraction(0.0)).
              input_status === InvalidDomain
        @test _irradiance_call(dhi = 1.0, partition = FixedDirectFraction(1.0)).
              input_status === InvalidDomain

        near_horizon = HeatStress._resolve_irradiance(
            ghi, nothing, nothing, FixedDirectFraction(0.8),
            _IRRADIANCE_TIME, deg2rad(89.5), LiljegrenConfig(),
        )
        @test ismissing(near_horizon.diagnostics.dni_w_m2)
        @test near_horizon.diagnostics.direct_fraction == 0.8

        clearness_at_cutoff = HeatStress._resolve_irradiance(
            ghi, nothing, nothing, LiljegrenClearnessFraction(),
            _IRRADIANCE_TIME, deg2rad(89.5), LiljegrenConfig(),
        )
        @test clearness_at_cutoff.diagnostics.direct_fraction == 0.0
        @test clearness_at_cutoff.diagnostics.dni_w_m2 == 0.0

        midnight = diagnose_liljegren(
            30.0, 20.0, 1.0,
            _IRRADIANCE_TIME + Hour(12), 0.0, 0.0,
        )
        @test midnight.irradiance.ghi_w_m2 == 0.0
        @test !midnight.solar_geometry_mismatch

        midnight_measured = diagnose_liljegren(
            30.0, 20.0, 1.0,
            _IRRADIANCE_TIME + Hour(12), 0.0, 0.0;
            ghi_w_m2 = 100.0,
        )
        @test midnight_measured.irradiance.ghi_w_m2 == 0.0
        @test midnight_measured.solar_geometry_mismatch
    end

    @testset "batch parity and row-wise absence" begin
        cases = (
            (ghi, dni, dhi),
            (ghi, dni, missing),
            (ghi, missing, dhi),
            (missing, dni, dhi),
            (ghi, missing, missing),
            (missing, dni, missing),
            (missing, missing, dhi),
            (missing, missing, missing),
        )
        ghi_values = Union{Missing,Float64}[case[1] for case in cases]
        dni_values = Union{Missing,Float64}[case[2] for case in cases]
        dhi_values = Union{Missing,Float64}[case[3] for case in cases]
        rows = length(cases)
        air = OffsetArray(fill(30.0, rows), -2:5)
        dew = OffsetArray(fill(20.0, rows), 3:10)
        wind = OffsetArray(fill(1.0, rows), 8:15)
        times = OffsetArray(fill(_IRRADIANCE_TIME, rows), -10:-3)
        batch = diagnose_liljegren_batch(
            air, dew, wind, times, 0.0, 0.0;
            ghi_w_m2 = OffsetArray(ghi_values, 20:27),
            dni_w_m2 = OffsetArray(dni_values, -20:-13),
            dhi_w_m2 = OffsetArray(dhi_values, 30:37),
            partition = FixedDirectFraction(fill(0.8, rows)),
        )
        scalar = [
            _irradiance_call(ghi = case[1], dni = case[2], dhi = case[3])
            for case in cases
        ]
        @test batch.result.wbgt_c == getproperty.(getproperty.(scalar, :result), :wbgt_c)
        @test batch.irradiance.ghi_w_m2 ==
              getproperty.(getproperty.(scalar, :irradiance), :ghi_w_m2)
        @test batch.irradiance.dni_w_m2 ==
              getproperty.(getproperty.(scalar, :irradiance), :dni_w_m2)
        @test batch.irradiance.dhi_w_m2 ==
              getproperty.(getproperty.(scalar, :irradiance), :dhi_w_m2)

        value_batch = liljegren_wbgt_batch(
            air, dew, wind, times, 0.0, 0.0;
            ghi_w_m2 = ghi_values, dni_w_m2 = dni_values, dhi_w_m2 = dhi_values,
            partition = FixedDirectFraction(fill(0.8, rows)), threaded = true,
        )
        outputs = ntuple(
            _ -> Vector{Union{Missing,Float64}}(undef, rows),
            3,
        )
        preallocated = liljegren_wbgt!(
            outputs..., air, dew, wind, times, 0.0, 0.0;
            ghi_w_m2 = ghi_values, dni_w_m2 = dni_values, dhi_w_m2 = dhi_values,
            partition = FixedDirectFraction(fill(0.8, rows)), threaded = true,
        )
        @test value_batch.wbgt_c == batch.result.wbgt_c
        @test preallocated.wbgt_c == batch.result.wbgt_c
    end

    @testset "type and breaking signature" begin
        diagnostic32 = diagnose_liljegren(
            30f0, 20f0, 1f0, _IRRADIANCE_TIME, 0f0, 0f0;
            ghi_w_m2 = 800f0, partition = FixedDirectFraction(0.8f0),
            pressure_hpa = 1010f0,
            config = LiljegrenConfig(
                solver = SolverConfig(
                    root_tolerance_k = 1f-6,
                    residual_tolerance_k = 1f-4,
                ),
            ),
        )
        @test diagnostic32 isa DiagnosticWBGTResult{Float32}
        @test diagnostic32.irradiance isa IrradianceDiagnostics{Float32}
        @test_throws MethodError liljegren_wbgt(
            30.0, 20.0, 1.0, 800.0, _IRRADIANCE_TIME, 0.0, 0.0,
        )
    end
end
