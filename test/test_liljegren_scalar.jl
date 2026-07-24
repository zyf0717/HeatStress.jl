using Test
using HeatStress
using Dates: Date, DateTime
using TimeZones: TimeZone, ZonedDateTime

const _diagnose_liljegren = HeatStress.diagnose_liljegren
const _liljegren_wbgt = HeatStress.liljegren_wbgt
const _globe_temperature = HeatStress.globe_temperature
const _natural_wet_bulb_temperature = HeatStress.natural_wet_bulb_temperature

function _scalar_fixture(; kwargs...)
    return _diagnose_liljegren(
        30.0,
        20.0,
        1.0,
        800.0,
        DateTime(2024, 6, 21, 12),
        0.0,
        0.0;
        direct_fraction = 0.7,
        kwargs...,
    )
end

@testset "Liljegren scalar model" begin
    @testset "ordinary value and diagnostic agreement" begin
        diagnostic = _scalar_fixture()
        value = _liljegren_wbgt(
            30.0,
            20.0,
            1.0,
            800.0,
            DateTime(2024, 6, 21, 12),
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test diagnostic isa DiagnosticWBGTResult{Float64}
        @test diagnostic.input_status === InputAccepted
        @test diagnostic.globe.reason === NoFailure
        @test diagnostic.natural_wet_bulb.reason === NoFailure
        @test diagnostic.result == value
        @test _globe_temperature(30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0; direct_fraction = 0.7) ==
              value.globe_temperature_c
        @test _natural_wet_bulb_temperature(30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0; direct_fraction = 0.7) ==
              value.natural_wet_bulb_c
        @test value.wbgt_c ≈
              0.7 * value.natural_wet_bulb_c + 0.2 * value.globe_temperature_c + 3.0
        @test abs(diagnostic.globe.validation_residual_k) <= diagnostic.globe.residual_tolerance_k
        @test abs(diagnostic.natural_wet_bulb.validation_residual_k) <=
              diagnostic.natural_wet_bulb.residual_tolerance_k
    end

    @testset "solar, wind, and dew-point policies" begin
        night = _diagnose_liljegren(
            30.0,
            20.0,
            1.0,
            800.0,
            DateTime(2024, 6, 21),
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test night.input_status === InputAccepted
        @test night.solar_geometry_mismatch
        @test !night.direct_solar_clipped
        @test !ismissing(night.result.wbgt_c)

        clipped = _diagnose_liljegren(
            30.0,
            20.0,
            1.0,
            600.0,
            DateTime(2024, 9, 22, 5, 55),
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test clipped.direct_solar_clipped
        @test !clipped.solar_geometry_mismatch

        zero_wind = _diagnose_liljegren(
            30.0,
            20.0,
            0.0,
            800.0,
            DateTime(2024, 6, 21, 12),
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test !zero_wind.wind_speed_clamped
        @test zero_wind.globe.converged
        @test zero_wind.natural_wet_bulb.converged

        saturated = _diagnose_liljegren(
            30.0,
            30.0,
            1.0,
            800.0,
            DateTime(2024, 6, 21, 12),
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test saturated.input_status === InputAccepted
        @test !saturated.dew_point_adjusted

        policy_input = (30.0, 31.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0)
        clamp = _diagnose_liljegren(policy_input...; direct_fraction = 0.7)
        swap = _diagnose_liljegren(
            policy_input...;
            direct_fraction = 0.7,
            config = LiljegrenConfig(dew_point_policy = SwapAirAndDewPoint, dew_point_tolerance_c = 0.0),
        )
        reject = _diagnose_liljegren(
            policy_input...;
            direct_fraction = 0.7,
            config = LiljegrenConfig(dew_point_policy = RejectInvalidDewPoint, dew_point_tolerance_c = 0.0),
        )
        @test clamp.dew_point_adjusted
        @test swap.dew_point_adjusted
        @test !ismissing(clamp.result.wbgt_c)
        @test !ismissing(swap.result.wbgt_c)
        @test reject.input_status === InvalidDewPoint
        @test ismissing(reject.result.wbgt_c)
        @test reject.globe.reason === reject.natural_wet_bulb.reason === NotAttempted
    end

    @testset "failures and partial component retention" begin
        missing_time = _diagnose_liljegren(
            30.0,
            20.0,
            1.0,
            800.0,
            missing,
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test missing_time.input_status === MissingTime
        @test missing_time.globe.reason === NotAttempted

        missing_meteorology = _diagnose_liljegren(
            missing,
            20.0,
            1.0,
            800.0,
            DateTime(2024, 6, 21, 12),
            0.0,
            0.0;
            direct_fraction = 0.7,
        )
        @test missing_meteorology.input_status === MissingMeteorology

        invalid_pressure = _diagnose_liljegren(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            pressure_hpa = 0.0, direct_fraction = 0.7,
        )
        invalid_fraction = _diagnose_liljegren(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 1.1,
        )
        @test invalid_pressure.input_status === InvalidDomain
        @test invalid_fraction.input_status === InvalidDomain
        invalid_longitude = _diagnose_liljegren(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 181.0, 0.0;
            direct_fraction = 0.7,
        )
        invalid_latitude = _diagnose_liljegren(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, NaN;
            direct_fraction = 0.7,
        )
        invalid_temperature = _diagnose_liljegren(
            -274.0, -275.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )
        @test invalid_longitude.input_status === InvalidDomain
        @test invalid_latitude.input_status === InvalidDomain
        @test invalid_temperature.input_status === InvalidDomain
        @test_throws ArgumentError LiljegrenConfig(globe_diameter_m = 0.0)
        @test_throws MethodError _diagnose_liljegren(30.0, 20.0, 1.0, 800.0, Date(2024, 6, 21), 0.0, 0.0; direct_fraction = 0.7)

        # Near-horizon direct forcing can exceed the globe guardrail while the
        # natural-wet-bulb balance remains valid; retain the valid component.
        partial = _diagnose_liljegren(
            30.0,
            20.0,
            1.0,
            1200.0,
            DateTime(2024, 9, 22, 6),
            0.0,
            0.0;
            direct_fraction = 0.8,
        )
        @test partial.globe.reason === Unbracketed
        @test partial.natural_wet_bulb.reason === NoFailure
        @test ismissing(partial.result.globe_temperature_c)
        @test !ismissing(partial.result.natural_wet_bulb_c)
        @test ismissing(partial.result.wbgt_c)
    end

    @testset "time-zone and Float32 consistency" begin
        utc = ZonedDateTime(DateTime(2024, 6, 21, 12), TimeZone("UTC"))
        new_york = ZonedDateTime(DateTime(2024, 6, 21, 8), TimeZone("America/New_York"))
        first = _diagnose_liljegren(30.0, 20.0, 1.0, 800.0, utc, -74.0, 40.7; direct_fraction = 0.7)
        second = _diagnose_liljegren(30.0, 20.0, 1.0, 800.0, new_york, -74.0, 40.7; direct_fraction = 0.7)
        @test first.result == second.result

        config32 = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            dew_point_tolerance_c = 1f-4,
        )
        diagnostic32 = _diagnose_liljegren(
            30f0, 20f0, 1f0, 800f0, DateTime(2024, 6, 21, 12), 0f0, 0f0;
            direct_fraction = 0.7f0, config = config32,
        )
        @test diagnostic32 isa DiagnosticWBGTResult{Float32}
        @test diagnostic32.globe.converged
        @test diagnostic32.natural_wet_bulb.converged
    end
end
