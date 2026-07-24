using Test
using HeatStress
using Dates

function _batch_inputs(rows = 4)
    return (
        fill(30.0, rows), fill(20.0, rows), fill(1.0, rows), fill(800.0, rows),
        [DateTime(2024, 6, 21, 12) + Minute(row - 1) for row in 1:rows],
    )
end

@testset "Liljegren batch model" begin
    air, dew, wind, radiation, time = _batch_inputs()
    serial = liljegren_wbgt_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
    @test length(serial.wbgt_c) == 4
    @test serial.wbgt_c[1] == HeatStress.liljegren_wbgt(air[1], dew[1], wind[1], radiation[1], time[1], 0.0, 0.0; direct_fraction = 0.7).wbgt_c
    one_row = liljegren_wbgt_batch(air[1:1], dew[1:1], wind[1:1], radiation[1:1], time[1:1], 0.0, 0.0; direct_fraction = 0.7)
    @test one_row.wbgt_c == serial.wbgt_c[1:1]

    threaded = liljegren_wbgt_batch(air, dew, wind, radiation, time, fill(0.0, 4), fill(0.0, 4); pressure_hpa = fill(1010.0, 4), direct_fraction = fill(0.7, 4), threaded = true)
    @test threaded.wbgt_c == serial.wbgt_c
    @test threaded.natural_wet_bulb_c == serial.natural_wet_bulb_c
    @test threaded.globe_temperature_c == serial.globe_temperature_c

    grouped_longitude = [0.0, 10.0, 0.0, 10.0]
    unique_latitude = [-10.0, 0.0, 10.0, 20.0]
    grouped = liljegren_wbgt_batch(view(air, :), view(dew, :), view(wind, :), view(radiation, :), view(time, :), grouped_longitude, unique_latitude; direct_fraction = 0.7)
    expected = [HeatStress.liljegren_wbgt(air[row], dew[row], wind[row], radiation[row], time[row], grouped_longitude[row], unique_latitude[row]; direct_fraction = 0.7).wbgt_c for row in 1:4]
    @test grouped.wbgt_c == expected

    wbgt = fill!(Vector{Union{Missing,Float64}}(undef, 4), missing)
    wet = fill!(Vector{Union{Missing,Float64}}(undef, 4), missing)
    globe = fill!(Vector{Union{Missing,Float64}}(undef, 4), missing)
    preallocated = liljegren_wbgt!(wbgt, wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
    @test preallocated.wbgt_c == serial.wbgt_c
    @test preallocated.natural_wet_bulb_c == serial.natural_wet_bulb_c
    @test preallocated.globe_temperature_c == serial.globe_temperature_c
    original = copy(wbgt)
    @test_throws ArgumentError liljegren_wbgt!(wbgt[1:3], wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
    @test wbgt == original
    @test_throws ArgumentError liljegren_wbgt!(Vector{Float64}(undef, 4), wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
    @test wbgt == original
    @test_throws ArgumentError liljegren_wbgt_batch(air[1:3], dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)

    empty = liljegren_wbgt_batch(Float64[], Float64[], Float64[], Float64[], DateTime[], 0.0, 0.0; direct_fraction = 0.7)
    @test isempty(empty.wbgt_c)
    diagnostic = diagnose_liljegren_batch([30.0, missing], dew[1:2], wind[1:2], radiation[1:2], time[1:2], 0.0, 0.0; direct_fraction = 0.7, threaded = true)
    @test diagnostic.rows == 2
    @test diagnostic.input_status == [InputAccepted, MissingMeteorology]
    @test diagnostic.globe.evaluations[1] > 0
    @test diagnostic.globe.evaluations[2] == 0
    diagnostic_serial = diagnose_liljegren_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
    diagnostic_threaded = diagnose_liljegren_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7, threaded = true)
    @test diagnostic_threaded.result.wbgt_c == diagnostic_serial.result.wbgt_c
    @test diagnostic_threaded.input_status == diagnostic_serial.input_status
    @test diagnostic_threaded.globe.evaluations == diagnostic_serial.globe.evaluations
    @test_throws ArgumentError diagnose_liljegren_batch(air, dew, wind, radiation, time, [0.0, 1.0], 0.0; direct_fraction = 0.7)

    @test @allocated(liljegren_wbgt!(wbgt, wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)) <
          @allocated(liljegren_wbgt_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7))
end
