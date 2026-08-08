using CSV
using Dates
using Test

@testset "RCC aligned batches" begin
    rows = collect(CSV.File(_RCC_FIXTURE))
    air = getproperty.(rows, :air_temperature_c)
    humidity = getproperty.(rows, :relative_humidity_percent)
    wind = getproperty.(rows, :wind_speed_m_s)
    time = DateTime.(getproperty.(rows, :time))
    longitude = getproperty.(rows, :longitude_deg)
    latitude = getproperty.(rows, :latitude_deg)
    ghi = getproperty.(rows, :ghi_w_m2)
    pressure = getproperty.(rows, :pressure_hpa)
    direct = getproperty.(rows, :direct_fraction)
    policy = FixedDirectFraction(direct)

    scalar_rccd = [
        rccd167l_wbgt(
            air[i], humidity[i], wind[i], time[i], longitude[i], latitude[i];
            ghi_w_m2 = ghi[i], pressure_hpa = pressure[i],
            partition = FixedDirectFraction(direct[i]),
        ) for i in eachindex(air)
    ]
    scalar_nws = [
        rcc_nws_wbgt(
            air[i], humidity[i], wind[i], time[i], longitude[i], latitude[i];
            ghi_w_m2 = ghi[i], pressure_hpa = pressure[i],
            partition = FixedDirectFraction(direct[i]),
        ) for i in eachindex(air)
    ]

    for (batch_function, scalar) in (
        (rccd167l_wbgt_batch, scalar_rccd),
        (rcc_nws_wbgt_batch, scalar_nws),
    )
        batch = batch_function(
            air, humidity, wind, time, longitude, latitude;
            ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
        )
        @test batch.wbgt_c == getproperty.(scalar, :wbgt_c)
        @test batch.natural_wet_bulb_c == getproperty.(scalar, :natural_wet_bulb_c)
        @test batch.globe_temperature_c == getproperty.(scalar, :globe_temperature_c)
    end

    for (mutating, scalar) in (
        (rccd167l_wbgt!, scalar_rccd),
        (rcc_nws_wbgt!, scalar_nws),
    )
        wbgt = fill!(Vector{Union{Missing,Float64}}(undef, length(rows)), missing)
        wet = similar(wbgt)
        globe = similar(wbgt)
        result = mutating(
            wbgt, wet, globe,
            air, humidity, wind, time, longitude, latitude;
            ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
        )
        @test result.wbgt_c === wbgt
        @test result.natural_wet_bulb_c === wet
        @test result.globe_temperature_c === globe
        @test wbgt == getproperty.(scalar, :wbgt_c)
        @test wet == getproperty.(scalar, :natural_wet_bulb_c)
        @test globe == getproperty.(scalar, :globe_temperature_c)
    end

    shared = rccd167l_wbgt_batch(
        air, humidity, wind, fill(DateTime(2025, 7, 1, 12), length(rows)), 0.0, 0.0;
        ghi_w_m2 = 500.0,
        pressure_hpa = 950.0,
        partition = FixedDirectFraction(0.5),
    )
    @test length(shared.wbgt_c) == length(rows)

    air_missing = Union{Missing,Float64}[air...]
    air_missing[2] = missing
    missing_batch = rcc_nws_wbgt_batch(
        air_missing, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
    )
    @test ismissing(missing_batch.wbgt_c[2])
    @test ismissing(missing_batch.natural_wet_bulb_c[2])
    @test ismissing(missing_batch.globe_temperature_c[2])

    missing_pressure = rccd167l_wbgt_batch(
        air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi,
        pressure_hpa = fill(missing, length(rows)),
        partition = policy,
    )
    @test all(ismissing, missing_pressure.wbgt_c)
    @test all(ismissing, missing_pressure.natural_wet_bulb_c)
    @test all(!ismissing, missing_pressure.globe_temperature_c)

    air32 = Float32.(air[1:2])
    batch32 = rccd167l_wbgt_batch(
        air32,
        Float32.(humidity[1:2]),
        Float32.(wind[1:2]),
        time[1:2],
        Float32.(longitude[1:2]),
        Float32.(latitude[1:2]);
        ghi_w_m2 = Float32.(ghi[1:2]),
        pressure_hpa = Float32.(pressure[1:2]),
        partition = FixedDirectFraction(Float32.(direct[1:2])),
    )
    @test batch32 isa WBGTBatchResult{Float32}

    @test_throws ArgumentError rccd167l_wbgt_batch(
        air, humidity[1:end-1], wind, time, longitude, latitude;
        ghi_w_m2 = ghi,
    )
    @test_throws ArgumentError rccd167l_wbgt_batch(
        air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi[1:end-1],
    )
    @test_throws ArgumentError rccd167l_wbgt_batch(
        air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, threaded = true,
    )

    output = fill!(Vector{Union{Missing,Float64}}(undef, length(rows)), missing)
    original = copy(output)
    @test_throws ArgumentError rccd167l_wbgt!(
        output, output, similar(output),
        air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
    )
    @test isequal(output, original)
    @test_throws ArgumentError rccd167l_wbgt!(
        output[1:end-1], similar(output), similar(output),
        air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
    )
    @test isequal(output, original)
    aliased_air = Union{Missing,Float64}[air...]
    @test_throws ArgumentError rccd167l_wbgt!(
        aliased_air, similar(output), similar(output),
        aliased_air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
    )
    @test aliased_air == air
    @test_throws ArgumentError rccd167l_wbgt!(
        output, similar(output), similar(output),
        air, humidity, wind, time, longitude, latitude;
        ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
        threaded = true,
    )
    @test isequal(output, original)

    invalid_wind = copy(wind)
    invalid_wind[2] = 0.0
    @test_throws ArgumentError rccd167l_wbgt!(
        output, similar(output), similar(output),
        air, humidity, invalid_wind, time, longitude, latitude;
        ghi_w_m2 = ghi, pressure_hpa = pressure, partition = policy,
    )
    @test isequal(output, original)

    nws_zero_wind = rcc_nws_wbgt_batch(
        [30.0], [50.0], [0.0], [DateTime(2025, 7, 1, 12)], 0.0, 0.0;
        ghi_w_m2 = 500.0,
        partition = FixedDirectFraction(0.7),
    )
    @test isfinite(only(nws_zero_wind.wbgt_c))
end
