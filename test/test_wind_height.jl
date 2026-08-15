using Dates

@testset "wind-height preprocessing" begin
    @testset "public policies and power law" begin
        @test NoWindHeightAdjustment() isa WindHeightPolicy
        @test LiljegrenStabilityPowerLaw() isa WindHeightPolicy
        @test Rural() isa WindTerrain
        @test Urban() isa WindTerrain
        @test StabilityA isa PasquillStabilityClass

        unchanged = diagnose_wind_speed_at_height(
            0.1,
            10.0;
            policy = NoWindHeightAdjustment(),
            minimum_wind_speed_m_s = 0.13,
        )
        @test unchanged.wind_speed_at_reference_height_m_s == 0.1
        @test unchanged.effective_wind_speed_m_s == 0.13
        @test unchanged.minimum_wind_floor_applied
        @test !unchanged.height_adjusted
        @test isnothing(unchanged.stability_class)

        for supplied in (0.13, 0.14)
            above_or_equal = diagnose_wind_speed_at_height(
                supplied,
                10.0;
                policy = NoWindHeightAdjustment(),
                minimum_wind_speed_m_s = 0.13,
            )
            @test above_or_equal.effective_wind_speed_m_s == supplied
            @test !above_or_equal.minimum_wind_floor_applied
        end

        for (terrain, exponents) in (
            (Rural(), (0.07, 0.07, 0.10, 0.15, 0.35, 0.55)),
            (Urban(), (0.15, 0.15, 0.20, 0.25, 0.30, 0.30)),
        )
            for (stability, exponent) in zip(instances(PasquillStabilityClass), exponents)
                diagnostic = diagnose_wind_speed_at_height(
                    5.0,
                    10.0;
                    terrain,
                    stability_class = stability,
                )
                @test diagnostic.power_law_exponent == exponent
                @test diagnostic.wind_speed_at_reference_height_m_s ≈
                      5.0 * (2.0 / 10.0)^exponent
                @test diagnostic.stability_class === stability
                @test diagnostic.stability_class_supplied
                @test diagnostic.height_adjusted
            end
        end

        @test wind_speed_at_height(
            5f0,
            10f0;
            reference_height_m = 2f0,
            stability_class = StabilityD,
        ) isa Float32
        @test wind_speed_at_height(
            big"5",
            big"10";
            reference_height_m = big"2",
            stability_class = StabilityD,
        ) isa BigFloat
        @test wind_speed_at_height(
            5.0,
            2.0;
            stability_class = StabilityF,
        ) == 5.0
    end

    @testset "EPA SRDT classification" begin
        daytime_winds = (1.0, 2.0, 3.0, 5.0, 6.0)
        irradiances = (925.0, 675.0, 175.0, 0.0)
        expected = (
            (StabilityA, StabilityA, StabilityB, StabilityD),
            (StabilityA, StabilityB, StabilityC, StabilityD),
            (StabilityB, StabilityB, StabilityC, StabilityD),
            (StabilityC, StabilityC, StabilityD, StabilityD),
            (StabilityC, StabilityD, StabilityD, StabilityD),
        )
        for wind_index in eachindex(daytime_winds), radiation_index in eachindex(irradiances)
            diagnostic = diagnose_wind_speed_at_height(
                daytime_winds[wind_index],
                10.0;
                daytime = true,
                ghi_w_m2 = irradiances[radiation_index],
            )
            @test diagnostic.stability_class === expected[wind_index][radiation_index]
            @test !diagnostic.stability_class_supplied
        end

        @test diagnose_wind_speed_at_height(2.0 - eps(), 10.0; daytime = true, ghi_w_m2 = 675.0).stability_class === StabilityA
        @test diagnose_wind_speed_at_height(2.0, 10.0; daytime = true, ghi_w_m2 = 675.0).stability_class === StabilityB
        @test diagnose_wind_speed_at_height(3.0, 10.0; daytime = true, ghi_w_m2 = 925.0).stability_class === StabilityB
        @test diagnose_wind_speed_at_height(5.0, 10.0; daytime = true, ghi_w_m2 = 675.0).stability_class === StabilityC
        @test diagnose_wind_speed_at_height(6.0, 10.0; daytime = true, ghi_w_m2 = 925.0).stability_class === StabilityC

        nighttime_winds = (1.0, 2.0, 2.5)
        deltas = (-0.1, 0.0)
        nighttime_expected = (
            (StabilityE, StabilityF),
            (StabilityD, StabilityE),
            (StabilityD, StabilityD),
        )
        for wind_index in eachindex(nighttime_winds), delta_index in eachindex(deltas)
            diagnostic = diagnose_wind_speed_at_height(
                nighttime_winds[wind_index],
                10.0;
                daytime = false,
                vertical_temperature_difference_c = deltas[delta_index],
            )
            @test diagnostic.stability_class === nighttime_expected[wind_index][delta_index]
        end
    end

    @testset "standalone validation" begin
        @test_throws ArgumentError wind_speed_at_height(-0.1, 10.0; stability_class = StabilityD)
        @test_throws ArgumentError wind_speed_at_height(1.0, 0.0; stability_class = StabilityD)
        @test_throws ArgumentError wind_speed_at_height(Inf, 10.0; stability_class = StabilityD)
        @test_throws ArgumentError wind_speed_at_height(1.0, 10.0)
        @test_throws ArgumentError wind_speed_at_height(1.0, 10.0; daytime = true)
        @test_throws ArgumentError wind_speed_at_height(1.0, 10.0; daytime = false)
        @test_throws ArgumentError wind_speed_at_height(
            1.0,
            10.0;
            policy = NoWindHeightAdjustment(),
            stability_class = StabilityD,
        )
    end

    @testset "Liljegren integration" begin
        time_day = DateTime(2024, 6, 21, 12)
        time_night = DateTime(2024, 6, 21, 0)
        common = (30.0, 20.0, 5.0, time_day, 0.0, 0.0)
        legacy = liljegren_wbgt(common...; ghi_w_m2 = 800.0)
        no_op = liljegren_wbgt(
            common...;
            ghi_w_m2 = 800.0,
            wind_height_m = 10.0,
            wind_height_policy = NoWindHeightAdjustment(),
        )
        @test no_op == legacy

        adjusted_wind = wind_speed_at_height(
            5.0,
            10.0;
            stability_class = StabilityC,
        )
        expected = liljegren_wbgt(
            30.0,
            20.0,
            adjusted_wind,
            time_day,
            0.0,
            0.0;
            ghi_w_m2 = 800.0,
        )
        adjusted = liljegren_wbgt(
            common...;
            ghi_w_m2 = 800.0,
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityC,
        )
        @test adjusted == expected
        @test liljegren_wbgt(
            30f0,
            20f0,
            5f0,
            time_day,
            0f0,
            0f0;
            ghi_w_m2 = 800f0,
            partition = FixedDirectFraction(0.8f0),
            pressure_hpa = 1010f0,
            wind_height_m = 10f0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityC,
            config = LiljegrenConfig(
                solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            ),
        ) isa WBGTResult{Float32}
        @test globe_temperature(
            common...;
            ghi_w_m2 = 800.0,
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityC,
        ) == adjusted.globe_temperature_c
        @test natural_wet_bulb_temperature(
            common...;
            ghi_w_m2 = 800.0,
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityC,
        ) == adjusted.natural_wet_bulb_c

        diagnostic = diagnose_liljegren(
            30.0,
            20.0,
            -1.0,
            time_day,
            0.0,
            0.0;
            ghi_w_m2 = 800.0,
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityA,
        )
        @test diagnostic.wind_speed_clamped
        @test diagnostic.wind_height.supplied_wind_speed_m_s == -1.0
        @test diagnostic.wind_height.wind_speed_at_reference_height_m_s == 0.0
        @test diagnostic.wind_height.effective_wind_speed_m_s == 0.13
        @test diagnostic.wind_height.minimum_wind_floor_applied

        missing_delta = diagnose_liljegren(
            30.0,
            20.0,
            1.0,
            time_night,
            0.0,
            0.0;
            ghi_w_m2 = 0.0,
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
        )
        @test missing_delta.input_status === MissingMeteorology
        explicit_night = diagnose_liljegren(
            30.0,
            20.0,
            1.0,
            time_night,
            0.0,
            0.0;
            ghi_w_m2 = 0.0,
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityE,
        )
        @test explicit_night.input_status === InputAccepted

        missing_time = diagnose_liljegren(
            30.0,
            20.0,
            3.0,
            missing,
            0.0,
            0.0;
            wind_height_m = 10.0,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = StabilityD,
        )
        @test missing_time.input_status === MissingTime
        @test missing_time.wind_height.supplied_wind_speed_m_s == 3.0
        @test missing_time.wind_height.measurement_height_m == 10.0
        @test ismissing(missing_time.wind_height.effective_wind_speed_m_s)

        air = [30.0, 30.0]
        dew = [20.0, 20.0]
        wind = [5.0, 1.0]
        times = [time_day, time_night]
        terrain = WindTerrain[Rural(), Urban()]
        classes = Union{Nothing,PasquillStabilityClass}[nothing, StabilityE]
        batch = diagnose_liljegren_batch(
            air,
            dew,
            wind,
            times,
            0.0,
            0.0;
            ghi_w_m2 = [800.0, 0.0],
            wind_height_m = [10.0, 10.0],
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            terrain,
            stability_class = classes,
            threaded = false,
        )
        threaded = diagnose_liljegren_batch(
            air,
            dew,
            wind,
            times,
            0.0,
            0.0;
            ghi_w_m2 = [800.0, 0.0],
            wind_height_m = [10.0, 10.0],
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            terrain,
            stability_class = classes,
            threaded = true,
        )
        @test batch.result.wbgt_c == threaded.result.wbgt_c
        @test batch.wind_height.stability_class == [StabilityC, StabilityE]
        @test batch.wind_height.stability_class_supplied == [false, true]

        wbgt = Vector{Union{Missing,Float64}}(undef, 2)
        wet = similar(wbgt)
        globe = similar(wbgt)
        preallocated = liljegren_wbgt!(
            wbgt,
            wet,
            globe,
            air,
            dew,
            wind,
            times,
            0.0,
            0.0;
            ghi_w_m2 = [800.0, 0.0],
            wind_height_m = [10.0, 10.0],
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            terrain,
            stability_class = classes,
        )
        @test preallocated.wbgt_c == batch.result.wbgt_c

        alias_output = Union{Missing,Float64}[10.0, 10.0]
        alias_wet = Union{Missing,Float64}[99.0, 99.0]
        alias_globe = Union{Missing,Float64}[99.0, 99.0]
        @test_throws ArgumentError liljegren_wbgt!(
            alias_output,
            alias_wet,
            alias_globe,
            air,
            dew,
            wind,
            times,
            0.0,
            0.0;
            ghi_w_m2 = [800.0, 0.0],
            wind_height_m = alias_output,
            wind_height_policy = LiljegrenStabilityPowerLaw(),
            stability_class = classes,
        )
        @test alias_output == [10.0, 10.0]
        @test alias_wet == [99.0, 99.0]
        @test alias_globe == [99.0, 99.0]

        @test_throws ArgumentError liljegren_wbgt(
            common...;
            ghi_w_m2 = 800.0,
            stability_class = StabilityC,
        )
    end
end
