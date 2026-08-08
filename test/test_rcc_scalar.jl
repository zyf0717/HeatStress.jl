using CSV
using Dates
using Test

@testset "RCC component and scalar models" begin
    rows = collect(CSV.File(_RCC_FIXTURE))
    for row in rows
        common = (
            row.air_temperature_c,
            row.relative_humidity_percent,
            row.wind_speed_m_s,
            row.ghi_w_m2,
        )
        nws_wet = rcc_nws_natural_wet_bulb_temperature(
            common...;
            pressure_hpa = row.pressure_hpa,
        )
        nonlinear_wet = rccnl_natural_wet_bulb_temperature(
            common...;
            pressure_hpa = row.pressure_hpa,
        )
        dim228 = dim228_globe_temperature(
            common...,
            row.solar_zenith_deg,
            row.direct_fraction,
        )
        dim167 = dim167l_globe_temperature(
            common...,
            row.solar_zenith_deg,
            row.direct_fraction,
        )
        @test nws_wet ≈ row.rcc_nws_natural_wet_bulb_c atol = row.atol_c rtol = row.rtol
        @test nonlinear_wet ≈ row.rccnl_natural_wet_bulb_c atol = row.atol_c rtol = row.rtol
        @test dim228 ≈ row.dim228_globe_c atol = row.atol_c rtol = row.rtol
        @test dim167 ≈ row.dim167l_globe_c atol = row.atol_c rtol = row.rtol

        policy = FixedDirectFraction(row.direct_fraction)
        nws = rcc_nws_wbgt(
            common[1:3]...,
            DateTime(row.time),
            row.longitude_deg,
            row.latitude_deg;
            ghi_w_m2 = row.ghi_w_m2,
            pressure_hpa = row.pressure_hpa,
            partition = policy,
        )
        rccd = rccd167l_wbgt(
            common[1:3]...,
            DateTime(row.time),
            row.longitude_deg,
            row.latitude_deg;
            ghi_w_m2 = row.ghi_w_m2,
            pressure_hpa = row.pressure_hpa,
            partition = policy,
        )
        @test nws.natural_wet_bulb_c ≈ row.rcc_nws_natural_wet_bulb_c atol = row.atol_c rtol = row.rtol
        @test nws.globe_temperature_c ≈ row.dim228_globe_c atol = row.atol_c rtol = row.rtol
        @test nws.wbgt_c ≈ row.rcc_nws_wbgt_c atol = row.atol_c rtol = row.rtol
        @test rccd.natural_wet_bulb_c ≈ row.rccnl_natural_wet_bulb_c atol = row.atol_c rtol = row.rtol
        @test rccd.globe_temperature_c ≈ row.dim167l_globe_c atol = row.atol_c rtol = row.rtol
        @test rccd.wbgt_c ≈ row.rccd167l_wbgt_c atol = row.atol_c rtol = row.rtol
    end

    # The source-defined 1 m/s Dimiceli floor applies before the wind exponent.
    globe_zero = dim167l_globe_temperature(30.0, 50.0, 0.0, 700.0, 30.0, 0.7)
    globe_floor = dim167l_globe_temperature(30.0, 50.0, 1.0, 700.0, 30.0, 0.7)
    @test globe_zero == globe_floor
    @test dim228_globe_temperature(30.0, 50.0, 0.0, 700.0, 30.0, 0.7) ==
          dim228_globe_temperature(30.0, 50.0, 1.0, 700.0, 30.0, 0.7)

    # At exactly 87 degrees the night coefficient owns the threshold.
    night_boundary = dim167l_globe_temperature(30.0, 50.0, 2.0, 0.0, 87.0, 0.7)
    night_later = dim167l_globe_temperature(30.0, 50.0, 2.0, 0.0, 100.0, 0.7)
    day_before = dim167l_globe_temperature(30.0, 50.0, 2.0, 0.0, prevfloat(87.0), 0.7)
    @test night_boundary == night_later
    @test day_before != night_boundary

    @test_throws ArgumentError rccnl_natural_wet_bulb_temperature(30.0, 50.0, 0.0, 500.0)
    @test isfinite(rcc_nws_natural_wet_bulb_temperature(30.0, 50.0, 0.0, 500.0))
    @test_throws ArgumentError rccnl_natural_wet_bulb_temperature(30.0, 50.0, -0.1, 500.0)
    @test_throws ArgumentError dim167l_globe_temperature(30.0, 50.0, 2.0, -1.0, 30.0, 0.7)
    @test_throws ArgumentError dim228_globe_temperature(30.0, 50.0, 2.0, 10.0, 90.0, 0.7)

    @test ismissing(rccnl_natural_wet_bulb_temperature(missing, 50.0, 1.0, 500.0))
    @test ismissing(dim167l_globe_temperature(30.0, missing, 1.0, 500.0, 30.0, 0.7))
    retained = rccd167l_wbgt(
        30.0, 50.0, 1.0, missing, 0.0, 0.0;
        ghi_w_m2 = 500.0,
        partition = FixedDirectFraction(0.7),
    )
    @test ismissing(retained.wbgt_c)
    @test !ismissing(retained.natural_wet_bulb_c)
    @test ismissing(retained.globe_temperature_c)

    retained_without_pressure = rccd167l_wbgt(
        30.0, 50.0, 1.0, DateTime(2025, 7, 1, 12), 0.0, 0.0;
        ghi_w_m2 = 500.0,
        pressure_hpa = missing,
        partition = FixedDirectFraction(0.7),
    )
    @test ismissing(retained_without_pressure.wbgt_c)
    @test ismissing(retained_without_pressure.natural_wet_bulb_c)
    @test !ismissing(retained_without_pressure.globe_temperature_c)

    zero_humidity = rcc_nws_wbgt(
        30.0, 0.0, 1.0, DateTime(2025, 7, 1, 12), 0.0, 0.0;
        ghi_w_m2 = 500.0,
        partition = FixedDirectFraction(0.7),
    )
    @test ismissing(zero_humidity.wbgt_c)
    @test ismissing(zero_humidity.natural_wet_bulb_c)
    @test !ismissing(zero_humidity.globe_temperature_c)

    result32 = rccd167l_wbgt(
        30f0, 50f0, 1f0, DateTime(2025, 7, 1, 12), 0f0, 0f0;
        ghi_w_m2 = 500f0,
        pressure_hpa = 900f0,
        partition = FixedDirectFraction(0.7f0),
    )
    @test result32 isa WBGTResult{Float32}
    @test all(value -> value isa Float32, (
        result32.wbgt_c,
        result32.natural_wet_bulb_c,
        result32.globe_temperature_c,
    ))

    @test all(isfinite, rccnl_natural_wet_bulb_temperature.(
        [25.0, 30.0], [50.0, 60.0], [1.0, 2.0], [400.0, 600.0],
    ))
    @test all(isfinite, dim167l_globe_temperature.(
        [25.0, 30.0], [50.0, 60.0], [1.0, 2.0], [400.0, 600.0],
        [30.0, 40.0], [0.6, 0.7],
    ))

    default_partition = rccd167l_wbgt(
        30.0, 50.0, 2.0, DateTime(2025, 7, 1, 12), 0.0, 0.0;
        ghi_w_m2 = 700.0,
    )
    @test isfinite(default_partition.wbgt_c)

    default_zero_radiation = rccd167l_wbgt(
        27.0, 75.0, 1.5, DateTime(2025, 7, 1), 0.0, 0.0;
        ghi_w_m2 = 0.0,
    )
    @test isfinite(default_zero_radiation.wbgt_c)
end
