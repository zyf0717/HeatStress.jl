function _normalized_for_test(
    ;
    air_temperature_c = 25.0,
    dew_point_c = 20.0,
    wind_speed_m_s = 1.0,
    solar_radiation_w_m2 = 600.0,
    time = HeatStress.Dates.DateTime(2024, 6, 21, 12),
    longitude_deg = 0.0,
    latitude_deg = 0.0,
    pressure_hpa = 1010.0,
    direct_fraction = 0.8,
    solar_zenith_rad = 0.5,
    config = LiljegrenConfig(),
)
    return HeatStress._normalize_meteorology(
        air_temperature_c,
        dew_point_c,
        wind_speed_m_s,
        solar_radiation_w_m2,
        time,
        longitude_deg,
        latitude_deg;
        pressure_hpa,
        direct_fraction,
        solar_zenith_rad,
        config,
    )
end

@testset "constants and input policies" begin
    @testset "constants and fixed configuration" begin
        @test HeatStress.KELVIN_OFFSET == 273.15
        @test HeatStress.GAS_CONSTANT_DRY_AIR ==
              HeatStress.UNIVERSAL_GAS_CONSTANT / HeatStress.MOLAR_MASS_DRY_AIR
        @test LiljegrenConfig().surface_albedo == HeatStress.DEFAULT_SURFACE_ALBEDO
        @test LiljegrenConfig().globe_diameter_m == HeatStress.DEFAULT_GLOBE_DIAMETER_M
        @test LiljegrenConfig().minimum_wind_speed_m_s ==
              HeatStress.DEFAULT_MINIMUM_WIND_SPEED_M_S
    end

    @testset "domain boundaries and non-finite values" begin
        @test HeatStress._validate_longitude_deg(-180.0) == -180.0
        @test HeatStress._validate_longitude_deg(180.0) == 180.0
        @test HeatStress._validate_latitude_deg(-90.0) == -90.0
        @test HeatStress._validate_latitude_deg(90.0) == 90.0
        @test HeatStress._validate_pressure_hpa(1.0) == 1.0
        @test HeatStress._validate_pressure_hpa(missing; allow_missing = true) === missing
        @test HeatStress._validate_direct_fraction(0.0) == 0.0
        @test HeatStress._validate_direct_fraction(1.0) == 1.0

        for value in (NaN, Inf, -Inf)
            @test_throws ArgumentError HeatStress._validate_longitude_deg(value)
            @test_throws ArgumentError HeatStress._validate_latitude_deg(value)
            @test_throws ArgumentError HeatStress._validate_pressure_hpa(value)
            @test_throws ArgumentError HeatStress._validate_direct_fraction(value)
        end
        @test_throws ArgumentError HeatStress._validate_longitude_deg(-180.1)
        @test_throws ArgumentError HeatStress._validate_latitude_deg(90.1)
        @test_throws ArgumentError HeatStress._validate_pressure_hpa(0.0)
        @test_throws ArgumentError HeatStress._validate_pressure_hpa(missing)
        @test_throws ArgumentError HeatStress._validate_direct_fraction(-0.01)
        @test_throws ArgumentError HeatStress._validate_direct_fraction(1.01)
        @test_throws ArgumentError SolverConfig(root_tolerance_k = NaN)
        @test_throws ArgumentError SolverConfig(residual_tolerance_k = Inf)
        @test_throws ArgumentError SolverConfig(maximum_iterations = 0)

        @test _normalized_for_test(air_temperature_c = NaN).status === InvalidDomain
        @test _normalized_for_test(solar_zenith_rad = Inf).status === InvalidDomain
        @test _normalized_for_test(air_temperature_c = missing).status === MissingMeteorology
        @test _normalized_for_test(time = missing).status === MissingTime
    end

    @testset "dew-point policies and tolerance" begin
        tolerance = 1.0
        clamp_config = LiljegrenConfig(dew_point_tolerance_c = tolerance)
        swap_config = LiljegrenConfig(
            dew_point_policy = SwapAirAndDewPoint,
            dew_point_tolerance_c = tolerance,
        )
        reject_config = LiljegrenConfig(
            dew_point_policy = RejectInvalidDewPoint,
            dew_point_tolerance_c = tolerance,
        )

        below = _normalized_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 20.5,
            config = clamp_config,
        )
        equal = _normalized_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.0,
            config = clamp_config,
        )
        above = _normalized_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.5,
            config = clamp_config,
        )
        unchanged = _normalized_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 20.0,
            config = clamp_config,
        )
        @test unchanged.dew_point_c == 20.0
        @test !unchanged.dew_point_adjusted
        @test below.dew_point_c == 20.0
        @test below.dew_point_adjusted
        @test equal.dew_point_c == 20.0
        @test equal.dew_point_adjusted
        @test above.dew_point_c == 20.0
        @test above.dew_point_adjusted

        swapped = _normalized_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.5,
            config = swap_config,
        )
        @test swapped.air_temperature_c == 21.5
        @test swapped.dew_point_c == 20.0
        @test swapped.dew_point_adjusted
        @test _normalized_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.5,
            config = reject_config,
        ).status === InvalidDewPoint
    end

    @testset "wind, radiation, and solar diagnostics" begin
        prepared = _normalized_for_test(
            wind_speed_m_s = -1.0,
            solar_radiation_w_m2 = -2.0,
        )
        @test prepared.wind_speed_m_s == 0.0
        @test prepared.solar_radiation_w_m2 == 0.0
        @test prepared.wind_speed_clamped
        @test prepared.solar_radiation_clamped
        @test !prepared.solar_geometry_mismatch
        @test HeatStress._effective_wind_speed_m_s(prepared.wind_speed_m_s, 0.13) == 0.13

        night = _normalized_for_test(solar_zenith_rad = pi)
        @test night.solar_radiation_w_m2 == 0.0
        @test night.solar_geometry_mismatch
        horizon = _normalized_for_test(solar_zenith_rad = pi / 2 + 1e-6)
        @test horizon.solar_radiation_w_m2 == 0.0
        @test horizon.solar_geometry_mismatch
    end

    @testset "Float32 and batch preflight" begin
        config32 = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            dew_point_tolerance_c = 1f-4,
        )
        prepared32 = _normalized_for_test(
            air_temperature_c = 25f0,
            dew_point_c = 20f0,
            wind_speed_m_s = 1f0,
            solar_radiation_w_m2 = 500f0,
            longitude_deg = 0f0,
            latitude_deg = 0f0,
            pressure_hpa = 1010f0,
            direct_fraction = 0.8f0,
            solar_zenith_rad = 0.5f0,
            config = config32,
        )
        @test prepared32 isa HeatStress._PreparedMeteorology{Float32}
        @test prepared32.air_temperature_k == 298.15f0

        output = Union{Missing,Float64}[missing, missing]
        @test_throws ArgumentError HeatStress._validate_batch_lengths([1.0, 2.0], [1.0])
        @test all(ismissing, output)
    end
end
