using CSV
using Test

const _RCC_FIXTURE = joinpath(@__DIR__, "..", "validation", "fixtures", "rcc_wbgt.csv")

@testset "RCC NWS psychrometrics" begin
    for row in CSV.File(_RCC_FIXTURE)
        value = psychrometric_wet_bulb_nws(
            row.air_temperature_c,
            row.relative_humidity_percent;
            pressure_hpa = row.pressure_hpa,
        )
        @test value ≈ row.psychrometric_wet_bulb_c atol = row.atol_c rtol = row.rtol
    end

    @test psychrometric_wet_bulb_nws(20.0, 100.0) == 20.0
    @test ismissing(psychrometric_wet_bulb_nws(20.0, 0.0))
    @test ismissing(psychrometric_wet_bulb_nws(missing, 50.0))
    @test ismissing(psychrometric_wet_bulb_nws(20.0, missing))
    @test ismissing(psychrometric_wet_bulb_nws(20.0, 50.0; pressure_hpa = missing))

    value32 = psychrometric_wet_bulb_nws(30f0, 45f0; pressure_hpa = 900f0)
    @test value32 isa Float32
    @test value32 ≈ Float32(psychrometric_wet_bulb_nws(30.0, 45.0; pressure_hpa = 900.0)) rtol = 2f-5

    broadcast_values = psychrometric_wet_bulb_nws.(
        [20.0, 30.0],
        [50.0, 70.0];
        pressure_hpa = 950.0,
    )
    @test broadcast_values == [
        psychrometric_wet_bulb_nws(20.0, 50.0; pressure_hpa = 950.0),
        psychrometric_wet_bulb_nws(30.0, 70.0; pressure_hpa = 950.0),
    ]

    @test_throws ArgumentError psychrometric_wet_bulb_nws(Inf, 50.0)
    @test_throws ArgumentError psychrometric_wet_bulb_nws(20.0, -eps())
    @test_throws ArgumentError psychrometric_wet_bulb_nws(20.0, 100.0 + eps(100.0))
    @test_throws ArgumentError psychrometric_wet_bulb_nws(20.0, 50.0; pressure_hpa = 0.0)
end
