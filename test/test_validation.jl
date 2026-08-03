function _basic_for_test(
    ;
    air_temperature_c = 25.0,
    dew_point_c = 20.0,
    wind_speed_m_s = 1.0,
    solar_radiation_w_m2 = 600.0,
    pressure_hpa = 1010.0,
    direct_fraction = 0.8,
    config = LiljegrenConfig(),
)
    return HeatStress._normalize_basic_meteorology(
        air_temperature_c,
        dew_point_c,
        wind_speed_m_s,
        solar_radiation_w_m2;
        pressure_hpa,
        direct_fraction,
        config,
    )
end

function _prepared_for_test(; solar_zenith_rad = 0.5, kwargs...)
    basic = _basic_for_test(; kwargs...)
    basic isa HeatStress._InputPreparationFailure && return basic
    return HeatStress._apply_solar_policy(
        basic, solar_zenith_rad, _irradiance_for_test(basic),
    )
end

function _irradiance_for_test(basic::HeatStress._BasicMeteorology{T}) where {T}
    return IrradianceDiagnostics{T}(
        basic.solar_radiation_w_m2,
        missing,
        missing,
        basic.direct_fraction,
        missing,
        true,
        false,
        false,
        false,
        true,
        true,
        basic.solar_radiation_clamped,
        false,
        false,
        false,
        missing,
        missing,
        false,
        :fixed,
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
        @test LiljegrenConfig(surface_albedo = 0.0).surface_albedo == 0.0
        @test LiljegrenConfig(surface_albedo = 1.0).surface_albedo == 1.0
        @test LiljegrenConfig(dew_point_tolerance_c = 0.0).dew_point_tolerance_c == 0.0
        @test LiljegrenConfig(minimum_wind_speed_m_s = 0.0).minimum_wind_speed_m_s == 0.0
        @test SolverConfig(residual_tolerance_k = 0.01).residual_tolerance_k == 0.01
        @test_throws ArgumentError SolverConfig(residual_tolerance_k = nextfloat(0.01))
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

        for value in (NaN, Inf, -Inf)
            @test_throws ArgumentError SolverConfig(root_tolerance_k = value)
            @test_throws ArgumentError SolverConfig(residual_tolerance_k = value)
            @test_throws ArgumentError LiljegrenConfig(dew_point_tolerance_c = value)
            @test_throws ArgumentError LiljegrenConfig(surface_albedo = value)
            @test_throws ArgumentError LiljegrenConfig(globe_diameter_m = value)
            @test_throws ArgumentError LiljegrenConfig(minimum_wind_speed_m_s = value)
        end

        for value in (NaN, Inf, -Inf)
            @test _basic_for_test(air_temperature_c = value).status === InvalidDomain
            @test _basic_for_test(dew_point_c = value).status === InvalidDomain
        end
        cold = _basic_for_test(air_temperature_c = -50.0, dew_point_c = -55.0)
        hot = _basic_for_test(air_temperature_c = 60.0, dew_point_c = 55.0)
        @test cold isa HeatStress._BasicMeteorology
        @test cold.air_temperature_c == -50.0
        @test cold.dew_point_c == -55.0
        @test hot isa HeatStress._BasicMeteorology
        @test hot.air_temperature_c == 60.0
        @test hot.dew_point_c == 55.0

        @test _basic_for_test(
            air_temperature_c = -HeatStress.KELVIN_OFFSET,
            dew_point_c = -HeatStress.KELVIN_OFFSET,
        ).status === InvalidDomain
        @test _basic_for_test(
            air_temperature_c = -273.0,
            dew_point_c = -HeatStress.KELVIN_OFFSET,
        ).status === InvalidDomain
        above_absolute_zero = nextfloat(-HeatStress.KELVIN_OFFSET)
        representable = _basic_for_test(
            air_temperature_c = above_absolute_zero,
            dew_point_c = above_absolute_zero,
        )
        @test representable isa HeatStress._BasicMeteorology
        @test representable.air_temperature_k > 0.0
        @test representable.dew_point_k > 0.0
        @test _basic_for_test(pressure_hpa = -1.0).status === InvalidDomain
        @test _basic_for_test(pressure_hpa = NaN).status === InvalidDomain
        @test _basic_for_test(pressure_hpa = Inf).status === InvalidDomain
        @test _basic_for_test(direct_fraction = -0.1).status === InvalidDomain
        @test _basic_for_test(direct_fraction = 1.1).status === InvalidDomain
        @test _basic_for_test(direct_fraction = NaN).status === InvalidDomain
        @test _basic_for_test(direct_fraction = Inf).status === InvalidDomain
        @test _basic_for_test(direct_fraction = missing).status === MissingMeteorology
        @test _basic_for_test(air_temperature_c = missing).status === MissingMeteorology
        basic = _basic_for_test()
        irradiance = _irradiance_for_test(basic)
        @test HeatStress._apply_solar_policy(basic, Inf, irradiance).status === InvalidDomain
        @test HeatStress._apply_solar_policy(basic, -0.1, irradiance).status === InvalidDomain
        @test HeatStress._apply_solar_policy(basic, 2pi, irradiance).status === InvalidDomain
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

        below = _basic_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 20.5,
            config = clamp_config,
        )
        equal = _basic_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.0,
            config = clamp_config,
        )
        above = _basic_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.5,
            config = clamp_config,
        )
        unchanged = _basic_for_test(
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

        swapped = _basic_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.5,
            config = swap_config,
        )
        @test swapped.air_temperature_c == 21.5
        @test swapped.dew_point_c == 20.0
        @test swapped.dew_point_adjusted
        @test _basic_for_test(
            air_temperature_c = 20.0,
            dew_point_c = 21.5,
            config = reject_config,
        ).status === InvalidDewPoint

        extreme_clamp = _basic_for_test(
            air_temperature_c = 60.0,
            dew_point_c = 62.0,
            config = clamp_config,
        )
        extreme_swap = _basic_for_test(
            air_temperature_c = 60.0,
            dew_point_c = 62.0,
            config = swap_config,
        )
        extreme_reject = _basic_for_test(
            air_temperature_c = 60.0,
            dew_point_c = 62.0,
            config = reject_config,
        )
        @test extreme_clamp.air_temperature_c == 60.0
        @test extreme_clamp.dew_point_c == 60.0
        @test extreme_swap.air_temperature_c == 62.0
        @test extreme_swap.dew_point_c == 60.0
        @test extreme_reject.status === InvalidDewPoint
        @test _basic_for_test(
            air_temperature_c = -274.0,
            dew_point_c = -272.0,
            config = clamp_config,
        ).status === InvalidDomain
        @test _basic_for_test(
            air_temperature_c = -274.0,
            dew_point_c = -272.0,
            config = swap_config,
        ).status === InvalidDomain
        @test _basic_for_test(
            air_temperature_c = -274.0,
            dew_point_c = -272.0,
            config = reject_config,
        ).status === InvalidDewPoint

        for config in (swap_config, reject_config)
            within_tolerance = _basic_for_test(
                air_temperature_c = 20.0,
                dew_point_c = 20.5,
                config = config,
            )
            at_tolerance = _basic_for_test(
                air_temperature_c = 20.0,
                dew_point_c = 21.0,
                config = config,
            )
            @test within_tolerance.air_temperature_c == 20.0
            @test within_tolerance.dew_point_c == 20.0
            @test within_tolerance.dew_point_adjusted
            @test at_tolerance.air_temperature_c == 20.0
            @test at_tolerance.dew_point_c == 20.0
            @test at_tolerance.dew_point_adjusted
        end
    end

    @testset "wind, radiation, and solar diagnostics" begin
        prepared = _prepared_for_test(
            wind_speed_m_s = -1.0,
            solar_radiation_w_m2 = -2.0,
        )
        @test prepared.wind_speed_m_s == 0.0
        @test prepared.solar_radiation_w_m2 == 0.0
        @test prepared.wind_speed_clamped
        @test prepared.solar_radiation_clamped
        @test !prepared.solar_geometry_mismatch
        @test HeatStress._effective_wind_speed_m_s(prepared.wind_speed_m_s, 0.13) == 0.13

        night = _prepared_for_test(solar_zenith_rad = pi)
        @test night.solar_radiation_w_m2 == 0.0
        @test night.solar_geometry_mismatch
        @test !night.direct_solar_clipped
        for T in (Float32, Float64)
            basic = _basic_for_test(
                air_temperature_c = T(25),
                dew_point_c = T(20),
                wind_speed_m_s = T(1),
                solar_radiation_w_m2 = T(600),
                pressure_hpa = T(1010),
                direct_fraction = T(0.8),
            )
            irradiance = _irradiance_for_test(basic)
            dawn = HeatStress._apply_solar_policy(basic, prevfloat(T(pi / 2)), irradiance)
            horizon = HeatStress._apply_solar_policy(basic, T(pi / 2), irradiance)
            night = HeatStress._apply_solar_policy(basic, nextfloat(T(pi / 2)), irradiance)
            @test dawn.solar_radiation_w_m2 == T(600)
            @test !dawn.solar_geometry_mismatch
            @test dawn.direct_solar_clipped
            @test horizon.solar_radiation_w_m2 == zero(T)
            @test horizon.solar_geometry_mismatch
            @test !horizon.direct_solar_clipped
            @test night.solar_radiation_w_m2 == zero(T)
            @test night.solar_geometry_mismatch
            @test !night.direct_solar_clipped
        end
        clipped = _prepared_for_test(
            solar_zenith_rad = pi / 2 - HeatStress.MINIMUM_DIRECT_SOLAR_ELEVATION_RAD / 2,
        )
        @test clipped.direct_solar_clipped
        daylight = _prepared_for_test(solar_zenith_rad = 0.5)
        @test daylight.solar_radiation_w_m2 == 600.0
        @test !daylight.solar_geometry_mismatch
        @test !daylight.direct_solar_clipped
    end

    @testset "Float32 and batch preflight" begin
        config32 = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            dew_point_tolerance_c = 1f-4,
        )
        Basic32 = Union{HeatStress._BasicMeteorology{Float32},HeatStress._InputPreparationFailure}
        Prepared32 = Union{HeatStress._PreparedMeteorology{Float32},HeatStress._InputPreparationFailure}
        basic32 = @inferred Basic32 HeatStress._normalize_basic_meteorology(
            25f0,
            20f0,
            1f0,
            500f0;
            pressure_hpa = 1010f0,
            direct_fraction = 0.8f0,
            config = config32,
        )
        prepared32 = @inferred Prepared32 HeatStress._apply_solar_policy(
            basic32, 0.5f0, _irradiance_for_test(basic32),
        )
        @test prepared32 isa HeatStress._PreparedMeteorology{Float32}
        @test prepared32.air_temperature_k == 298.15f0

        Basic64 = Union{HeatStress._BasicMeteorology{Float64},HeatStress._InputPreparationFailure}
        Prepared64 = Union{HeatStress._PreparedMeteorology{Float64},HeatStress._InputPreparationFailure}
        basic64 = @inferred Basic64 HeatStress._normalize_basic_meteorology(
            25.0,
            20.0,
            1.0,
            500.0;
            pressure_hpa = 1010.0,
            direct_fraction = 0.8,
        )
        prepared64 = @inferred Prepared64 HeatStress._apply_solar_policy(
            basic64, 0.5, _irradiance_for_test(basic64),
        )
        @test prepared64 isa HeatStress._PreparedMeteorology{Float64}

        @test_throws ArgumentError HeatStress._validate_batch_lengths([1.0, 2.0], [1.0])
    end
end
