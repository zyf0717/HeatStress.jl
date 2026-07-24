using Test
using HeatStress
using Dates: Date, DateTime
using TimeZones: TimeZone, ZonedDateTime

@testset "solar geometry" begin
    @testset "independent zenith fixtures" begin
        # NOAA Solar Calculator values (geometric zenith, no refraction),
        # checked 2026-07-24. The 2° tolerance is the published spec limit.
        fixtures = [
            (DateTime(2024, 3, 20, 12), 0.0, 0.0, 1.83),
            (DateTime(2024, 6, 21, 12), 0.0, 45.0, 21.56),
        ]
        for (time, longitude, latitude, expected_zenith) in fixtures
            @test HeatStress.solar_zenith(time, longitude, latitude) ≈ expected_zenith atol = 2.0
        end
    end

    @testset "calendar, horizon, and coordinate boundaries" begin
        @test isfinite(HeatStress.solar_zenith(DateTime(2024, 2, 29, 12), 0.0, 0.0))
        @test isfinite(HeatStress.solar_zenith(DateTime(2023, 3, 1, 12), 0.0, 0.0))
        @test HeatStress.solar_zenith(DateTime(2024, 6, 21), 0.0, 0.0) > 90.0
        @test HeatStress.solar_zenith(DateTime(2024, 6, 21, 12), 180.0, 0.0) ≈
              HeatStress.solar_zenith(DateTime(2024, 6, 21, 12), -180.0, 0.0)
        @test HeatStress.solar_zenith(DateTime(2024, 12, 21, 12), 0.0, 75.0) > 90.0
        @test_throws ArgumentError HeatStress.solar_zenith(DateTime(2024, 6, 21, 12), 181.0, 0.0)
        @test_throws ArgumentError HeatStress.solar_zenith(DateTime(2024, 6, 21, 12), 0.0, -91.0)
        @test_throws MethodError HeatStress.solar_zenith(Date(2024, 6, 21), 0.0, 0.0)
    end

    @testset "equivalent instants" begin
        utc = ZonedDateTime(DateTime(2024, 6, 21, 12), TimeZone("UTC"))
        new_york = ZonedDateTime(DateTime(2024, 6, 21, 8), TimeZone("America/New_York"))
        tokyo = ZonedDateTime(DateTime(2024, 6, 21, 21), TimeZone("Asia/Tokyo"))
        @test HeatStress.solar_zenith(utc, -74.0, 40.7) ≈ HeatStress.solar_zenith(new_york, -74.0, 40.7)
        @test HeatStress.solar_zenith(utc, -74.0, 40.7) ≈ HeatStress.solar_zenith(tokyo, -74.0, 40.7)
    end

    @testset "batch equals scalar and preserves order" begin
        times = [
            DateTime(2024, 6, 21, 12),
            DateTime(2024, 3, 20, 12),
            DateTime(2024, 6, 21, 12),
            DateTime(2024, 12, 21, 12),
        ]
        longitude = [0.0, 0.0, 10.0, 0.0]
        latitude = [45.0, 0.0, 45.0, 75.0]
        expected = HeatStress.solar_zenith.(times, longitude, latitude)
        @test HeatStress.solar_zenith_batch(times, longitude, latitude) ≈ expected
        @test HeatStress.solar_zenith_batch(times, 0.0, 45.0) ≈ HeatStress.solar_zenith.(times, 0.0, 45.0)
        @test HeatStress.solar_zenith_batch(DateTime[], 0.0, 45.0) == Float64[]
        @test_throws ArgumentError HeatStress.solar_zenith_batch(times, longitude[1:3], latitude)
    end

    @testset "numeric promotion" begin
        @test HeatStress.solar_zenith(DateTime(2024, 6, 21, 12), Float32(0), Float32(45)) isa Float64
    end
end
