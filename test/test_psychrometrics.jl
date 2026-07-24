using Test
using HeatStress

@testset "psychrometrics" begin
    @testset "FAO-56 saturation vapour pressure" begin
        @test HeatStress.saturation_vapour_pressure_hpa(0.0) ≈ 6.108
        @test HeatStress.saturation_vapour_pressure_hpa(20.0) ≈ 23.383 atol = 0.001
        @test HeatStress.saturation_vapour_pressure_hpa(25.0) ≈ 31.678 atol = 0.001
        values = HeatStress.saturation_vapour_pressure_hpa.(range(-40.0, 50.0; length = 20))
        @test all(isfinite, values)
        @test all(diff(values) .> 0)
        @test HeatStress.saturation_vapour_pressure_hpa(BigFloat(25)) isa BigFloat
        @test HeatStress.saturation_vapour_pressure_hpa(20f0) isa Float32
    end

    @testset "humidity and vapour-pressure identities" begin
        @test HeatStress.relative_humidity_from_dewpoint(25.0, 25.0) ≈ 100.0
        @test HeatStress.relative_humidity_from_dewpoint(25.0, 15.0) ≈ 53.83 atol = 0.01
        @test 0 < HeatStress.relative_humidity_from_dewpoint(25.0, 15.0) < 100
        dew_points = range(-20.0, 24.0; length = 10)
        @test all(diff(HeatStress.relative_humidity_from_dewpoint.(25.0, dew_points)) .> 0)

        temperature = 30.0
        dew_point = 18.0
        humidity = HeatStress.relative_humidity_from_dewpoint(temperature, dew_point)
        @test HeatStress.vapour_pressure(temperature, humidity) ≈
              HeatStress.saturation_vapour_pressure_hpa(dew_point)
        @test HeatStress.vapour_pressure(25.0, 100.0) ≈ HeatStress.saturation_vapour_pressure_hpa(25.0)
        @test HeatStress.vapour_pressure.(fill(20.0, 2), [25.0, 50.0]) ≈
              [HeatStress.vapour_pressure(20.0, 25.0), HeatStress.vapour_pressure(20.0, 50.0)]
    end

    @testset "explicit domain failures" begin
        for value in (-40.1, 50.1, NaN, Inf, -Inf)
            @test_throws ArgumentError HeatStress.saturation_vapour_pressure_hpa(value)
        end
        @test_throws ArgumentError HeatStress.vapour_pressure(20.0, -0.1)
        @test_throws ArgumentError HeatStress.vapour_pressure(20.0, 100.1)
        @test_throws ArgumentError HeatStress.relative_humidity_from_dewpoint(20.0, 50.1)
    end
end
