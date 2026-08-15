using Test
using HeatStress
using Dates: Date, DateTime
using TimeZones: TimeZone, ZonedDateTime
using TOML

function _legacy_partition(value)
    return FixedDirectFraction{typeof(value)}(value)
end

function _diagnose_liljegren(air, dew, wind, ghi, time, longitude, latitude;
                             direct_fraction, kwargs...)
    return HeatStress.diagnose_liljegren(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _legacy_partition(direct_fraction), kwargs...,
    )
end

function _liljegren_wbgt(air, dew, wind, ghi, time, longitude, latitude;
                         direct_fraction, kwargs...)
    return HeatStress.liljegren_wbgt(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _legacy_partition(direct_fraction), kwargs...,
    )
end

function _globe_temperature(air, dew, wind, ghi, time, longitude, latitude;
                            direct_fraction, kwargs...)
    return HeatStress.globe_temperature(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _legacy_partition(direct_fraction), kwargs...,
    )
end

function _natural_wet_bulb_temperature(
    air, dew, wind, ghi, time, longitude, latitude;
    direct_fraction, kwargs...,
)
    return HeatStress.natural_wet_bulb_temperature(
        air, dew, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, partition = _legacy_partition(direct_fraction), kwargs...,
    )
end

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

function _scalar_value_call()
    return _liljegren_wbgt(
        30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
        direct_fraction = 0.7,
    )
end

function _scalar_value_allocations()
    _scalar_value_call() # compile and warm the public call before measuring it
    return @allocated _scalar_value_call()
end

function _scalar_value_allocations(config::LiljegrenConfig)
    _liljegren_wbgt(
        30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
        direct_fraction = 0.7, config,
    )
    return @allocated _liljegren_wbgt(
        30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
        direct_fraction = 0.7, config,
    )
end

function _generated_scalar_fixture_data(global_precision::Int)
    repository = dirname(@__DIR__)
    generator = joinpath(repository, "test", "fixtures", "generate_liljegren_scalar_references.jl")
    code = "setprecision(BigFloat, $global_precision); include(raw\"$generator\")"
    output = read(`$(Base.julia_cmd()) --startup-file=no --project=$repository -e $code`, String)
    return TOML.parse(output)
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

    @testset "independent scalar component fixtures" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "liljegren_scalar_reference.toml")
        fixture_data = TOML.parsefile(fixture_path)
        @test fixture_data["schema_version"] == 3
        @test fixture_data["precision_bits"] == 256
        @test fixture_data["generator_schema_version"] == 3
        @test fixture_data["generator_path"] == "test/fixtures/generate_liljegren_scalar_references.jl"
        @test "liljegren_2008" in fixture_data["source_identifiers"]
        for fixture in values(fixture_data["fixtures"])
            diagnostic = _diagnose_liljegren(
                fixture["air_temperature_c"],
                fixture["dew_point_c"],
                fixture["wind_speed_m_s"],
                fixture["solar_radiation_w_m2"],
                DateTime(fixture["time"]),
                fixture["longitude_deg"],
                fixture["latitude_deg"];
                pressure_hpa = fixture["pressure_hpa"],
                direct_fraction = fixture["direct_fraction"],
            )
            result = diagnostic.result
            @test result.globe_temperature_c ≈ parse(Float64, fixture["globe_temperature_c"]) atol = 1e-4 rtol = 1e-8
            @test result.natural_wet_bulb_c ≈ parse(Float64, fixture["natural_wet_bulb_c"]) atol = 1e-4 rtol = 1e-8
            @test result.wbgt_c ≈ parse(Float64, fixture["wbgt_c"]) atol = 1e-4 rtol = 1e-8
        end
    end

    @testset "fixture generation is precision-independent" begin
        generated_default = _generated_scalar_fixture_data(256)
        generated_changed = _generated_scalar_fixture_data(768)
        @test generated_default["fixtures"] == generated_changed["fixtures"]

        fixture_path = joinpath(@__DIR__, "fixtures", "liljegren_scalar_reference.toml")
        committed = TOML.parsefile(fixture_path)
        for (name, generated) in generated_default["fixtures"]
            committed_fixture = committed["fixtures"][name]
            @test generated["time"] == committed_fixture["time"]
            for field in ("globe_temperature_c", "natural_wet_bulb_c", "wbgt_c")
                @test parse(Float64, generated[field]) == parse(Float64, committed_fixture[field])
            end
        end
        @test occursin(".250", committed["fixtures"]["subminute"]["time"])
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
            DateTime(2024, 9, 22, 5, 54),
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

    @testset "extended temperature calculation domain" begin
        for (air_temperature_c, dew_point_c) in ((-50.0, -55.0), (60.0, 55.0))
            diagnostic = _diagnose_liljegren(
                air_temperature_c,
                dew_point_c,
                1.0,
                800.0,
                DateTime(2024, 6, 21, 12),
                0.0,
                0.0;
                direct_fraction = 0.7,
            )
            @test diagnostic.input_status === InvalidDomain
            @test diagnostic.globe.evaluations == 0
            @test diagnostic.natural_wet_bulb.evaluations == 0
            @test diagnostic.globe.reason === NotAttempted
            @test diagnostic.natural_wet_bulb.reason === NotAttempted
        end

        supported_dew_point = _diagnose_liljegren(
            60.0, 40.0, 1.0, 0.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )
        @test supported_dew_point.input_status === InputAccepted
        @test supported_dew_point.globe.reason === NoFailure
        @test supported_dew_point.natural_wet_bulb.reason === NoFailure

        bounded_root = _diagnose_liljegren(
            60.0, 50.0, 1.0, 0.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )
        @test bounded_root.input_status === InputAccepted
        @test bounded_root.globe.reason === NoFailure
        @test bounded_root.natural_wet_bulb.reason === Unbracketed
        @test !ismissing(bounded_root.result.globe_temperature_c)
        @test ismissing(bounded_root.result.natural_wet_bulb_c)
        @test ismissing(bounded_root.result.wbgt_c)

        zero_vapour_pressure_c = -237.3
        nonfinite_vapour_pressure_c = prevfloat(zero_vapour_pressure_c)
        @test HeatStress._saturation_vapour_pressure_hpa_unchecked(
            zero_vapour_pressure_c,
        ) == 0.0
        @test !isfinite(HeatStress._saturation_vapour_pressure_hpa_unchecked(
            nonfinite_vapour_pressure_c,
        ))
        @test HeatStress._saturation_vapour_pressure_hpa_unchecked(100.0) >= 1010.0
        @test HeatStress._air_thermal_conductivity(
            2000.0 + HeatStress.KELVIN_OFFSET,
        ) <= 0.0
        derived_state_failures = (
            (-230.0, zero_vapour_pressure_c),
            (-230.0, nonfinite_vapour_pressure_c),
            (100.0, 100.0),
        )
        for (air_temperature_c, dew_point_c) in derived_state_failures
            diagnostic = _diagnose_liljegren(
                air_temperature_c,
                dew_point_c,
                1.0,
                800.0,
                DateTime(2024, 6, 21, 12),
                0.0,
                0.0;
                direct_fraction = 0.7,
            )
            @test diagnostic.input_status === InvalidDomain
            @test diagnostic.globe.reason === NotAttempted
            @test diagnostic.natural_wet_bulb.reason === NotAttempted
            @test diagnostic.globe.evaluations == 0
            @test diagnostic.natural_wet_bulb.evaluations == 0
        end
        extreme_air = _diagnose_liljegren(
            2000.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )
        @test extreme_air.input_status === InputAccepted
        @test extreme_air.globe.reason === NoFailure
        @test extreme_air.natural_wet_bulb.reason === Unbracketed
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
            pressure_hpa = 1010f0, direct_fraction = 0.7f0, config = config32,
        )
        @test diagnostic32 isa DiagnosticWBGTResult{Float32}
        @test diagnostic32.globe.converged
        @test diagnostic32.natural_wet_bulb.converged
    end

    @testset "public-call inference and scalar allocations" begin
        @test (@inferred Union{Missing,Float64} _globe_temperature(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )) isa Float64
        @test (@inferred Union{Missing,Float64} _natural_wet_bulb_temperature(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )) isa Float64
        @test (@inferred _liljegren_wbgt(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )) isa WBGTResult{Float64}
        @test (@inferred _diagnose_liljegren(
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0;
            direct_fraction = 0.7,
        )) isa DiagnosticWBGTResult{Float64}

        config32 = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            dew_point_tolerance_c = 1f-4,
        )
        @test (@inferred _diagnose_liljegren(
            30f0, 20f0, 1f0, 800f0, DateTime(2024, 6, 21, 12), 0f0, 0f0;
            pressure_hpa = 1010f0, direct_fraction = 0.7f0, config = config32,
        )) isa DiagnosticWBGTResult{Float32}

        @test _scalar_value_allocations() <= 1536
        strict_allocations = _scalar_value_allocations(LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1e-8, residual_tolerance_k = 1e-4),
        ))
        @test strict_allocations <= _scalar_value_allocations()
    end

    @testset "public signatures and mixed-precision failures" begin
        config32 = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            dew_point_tolerance_c = 1f-4,
        )
        arguments = (30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0)
        default_pressure = _diagnose_liljegren(arguments...; direct_fraction = 0.7)
        explicit_pressure = _diagnose_liljegren(arguments...; pressure_hpa = HeatStress.DEFAULT_PRESSURE_HPA, direct_fraction = 0.7)
        @test default_pressure == explicit_pressure
        @test_throws MethodError _diagnose_liljegren(arguments...; pressure_hpa = nothing, direct_fraction = 0.7)

        missing_pressure = _diagnose_liljegren(arguments...; pressure_hpa = missing, direct_fraction = 0.7)
        @test missing_pressure.input_status === MissingMeteorology
        @test_throws MethodError _diagnose_liljegren(30.0, 20.0, 1.0, 800.0, Date(2024, 6, 21), 0.0, 0.0; direct_fraction = 0.7)

        accepted = @inferred _diagnose_liljegren(arguments...; direct_fraction = 0.7, config = config32)
        invalid_longitude = @inferred _diagnose_liljegren(30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 181.0, 0.0; direct_fraction = 0.7, config = config32)
        supported_temperature = @inferred _diagnose_liljegren(60.0, 40.0, 1.0, 0.0, DateTime(2024, 6, 21, 12), 0.0, 0.0; direct_fraction = 0.7, config = config32)
        missing_meteorology = @inferred _diagnose_liljegren(missing, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0; direct_fraction = 0.7, config = config32)
        missing_time = @inferred _diagnose_liljegren(30.0, 20.0, 1.0, 800.0, missing, 0.0, 0.0; direct_fraction = 0.7, config = config32)
        for diagnostic in (accepted, invalid_longitude, supported_temperature, missing_meteorology, missing_time)
            @test diagnostic isa DiagnosticWBGTResult{Float64}
        end
        @test invalid_longitude.input_status === InvalidDomain
        @test supported_temperature.input_status === InputAccepted
        @test supported_temperature.globe.reason === NoFailure
        @test supported_temperature.natural_wet_bulb.reason === NoFailure
        @test missing_meteorology.input_status === MissingMeteorology
        @test missing_time.input_status === MissingTime
        @test _liljegren_wbgt(missing, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0; direct_fraction = 0.7, config = config32) ==
              missing_meteorology.result
        @test _liljegren_wbgt(30.0, 20.0, 1.0, 800.0, missing, 0.0, 0.0; direct_fraction = 0.7, config = config32) ==
              missing_time.result

        partial_arguments = (30.0, 20.0, 1.0, 1200.0, DateTime(2024, 9, 22, 6), 0.0, 0.0)
        @test _liljegren_wbgt(partial_arguments...; direct_fraction = 0.8) ==
              _diagnose_liljegren(partial_arguments...; direct_fraction = 0.8).result
    end
end
