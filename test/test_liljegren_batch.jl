using Test
using HeatStress
using Dates
using OffsetArrays
using TOML

function _batch_inputs(rows::Int = 4; float_type::Type{<:AbstractFloat} = Float64)
    T = float_type
    return (
        fill(T(30), rows), fill(T(20), rows), fill(T(1), rows), fill(T(800), rows),
        [DateTime(2024, 6, 21, 12) + Minute(row - 1) for row in 1:rows],
    )
end

function _scalar_row_results(air, dew, wind, radiation, time, longitude, latitude; pressure_hpa = 1010, direct_fraction, config = LiljegrenConfig())
    rows = length(air)
    return [HeatStress.liljegren_wbgt(
        HeatStress._at(air, row), HeatStress._at(dew, row), HeatStress._at(wind, row),
        HeatStress._at(radiation, row), HeatStress._at(time, row),
        HeatStress._at(longitude, row), HeatStress._at(latitude, row);
        pressure_hpa = HeatStress._at(pressure_hpa, row),
        direct_fraction = HeatStress._at(direct_fraction, row), config,
    ) for row in 1:rows]
end

function _assert_matches_scalar(batch, expected)
    @test isequal(
        [batch.wbgt_c[firstindex(batch.wbgt_c) + row - 1] for row in eachindex(expected)],
        [value.wbgt_c for value in expected],
    )
    @test isequal(
        [batch.natural_wet_bulb_c[firstindex(batch.natural_wet_bulb_c) + row - 1] for row in eachindex(expected)],
        [value.natural_wet_bulb_c for value in expected],
    )
    @test isequal(
        [batch.globe_temperature_c[firstindex(batch.globe_temperature_c) + row - 1] for row in eachindex(expected)],
        [value.globe_temperature_c for value in expected],
    )
end

function _sentinel_outputs(rows::Int)
    output() = fill!(Vector{Union{Missing,Float64}}(undef, rows), -999.0)
    return output(), output(), output()
end

function _assert_premutation_failure(call, outputs::AbstractVector...)
    original = copy.(outputs)
    @test_throws ArgumentError call()
    for (output, expected) in zip(outputs, original)
        @test output == expected
    end
end

function _assert_component_diagnostics_equal(actual, expected)
    for field in fieldnames(SolverDiagnosticsBatch)
        @test isequal(getproperty(actual, field), getproperty(expected, field))
    end
end

@testset "Liljegren batch model" begin
    get(ENV, "HEATSTRESS_EXPECT_MULTITHREADED", "false") == "true" && @test Threads.nthreads() > 1

    @testset "ordinary, preallocated, and threaded equivalence" begin
        air, dew, wind, radiation, time = _batch_inputs()
        serial = liljegren_wbgt_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
        expected = _scalar_row_results(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
        _assert_matches_scalar(serial, expected)

        wbgt, wet, globe = _sentinel_outputs(4)
        preallocated = liljegren_wbgt!(wbgt, wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
        _assert_matches_scalar(preallocated, expected)

        threaded = liljegren_wbgt_batch(
            air, dew, wind, radiation, time, fill(0.0, 4), fill(0.0, 4);
            pressure_hpa = fill(1010.0, 4), direct_fraction = fill(0.7, 4), threaded = true,
        )
        @test threaded.wbgt_c == serial.wbgt_c
        @test threaded.natural_wet_bulb_c == serial.natural_wet_bulb_c
        @test threaded.globe_temperature_c == serial.globe_temperature_c

        one_row = liljegren_wbgt_batch(air[1:1], dew[1:1], wind[1:1], radiation[1:1], time[1:1], 0.0, 0.0; direct_fraction = 0.7)
        @test one_row.wbgt_c == serial.wbgt_c[1:1]
        empty = liljegren_wbgt_batch(Float64[], Float64[], Float64[], Float64[], DateTime[], 0.0, 0.0; direct_fraction = 0.7)
        @test isempty(empty.wbgt_c)
    end

    @testset "shared typed row execution" begin
        air, dew, wind, radiation, time = _batch_inputs(1)
        config = HeatStress._config_as_type(Float64, LiljegrenConfig())
        from_time = HeatStress._liljegren_row_from_time(
            air[1], dew[1], wind[1], radiation[1], time[1], -74.0060, 40.7128,
            1010.0, 0.7, config, HeatStress._ValueMode(),
        )
        zenith = deg2rad(HeatStress.solar_zenith(time[1], -74.0060, 40.7128))
        from_zenith = HeatStress._liljegren_row_from_zenith(
            air[1], dew[1], wind[1], radiation[1], zenith, 1010.0, 0.7,
            config, HeatStress._ValueMode(),
        )
        scalar = HeatStress.liljegren_wbgt(
            air[1], dew[1], wind[1], radiation[1], time[1], -74.0060, 40.7128;
            pressure_hpa = 1010.0, direct_fraction = 0.7,
        )
        @test isequal(from_time.wbgt_c, from_zenith.wbgt_c)
        @test isequal(from_time.wbgt_c, scalar.wbgt_c)
        @test isequal(from_time.natural_wet_bulb_c, from_zenith.natural_wet_bulb_c)
        @test isequal(from_time.natural_wet_bulb_c, scalar.natural_wet_bulb_c)
        @test isequal(from_time.globe_temperature_c, from_zenith.globe_temperature_c)
        @test isequal(from_time.globe_temperature_c, scalar.globe_temperature_c)
        @test isbitstype(typeof(from_time))
    end

    @testset "cached solar preparation preserves row semantics" begin
        air, dew, wind, radiation, _ = _batch_inputs()
        repeated_time = DateTime(2024, 6, 21, 12)
        time = Union{Missing,DateTime}[repeated_time, repeated_time, missing, repeated_time]
        longitude = [0.0, 0.0, 0.0, 181.0]
        latitude = fill(45.0, 4)
        zenith = HeatStress._batch_solar_zenith(4, time, longitude, latitude)
        expected_zenith = HeatStress.solar_zenith(repeated_time, 0.0, 45.0)
        @test zenith[1] == expected_zenith
        @test zenith[2] == expected_zenith
        @test isnan(zenith[3])
        @test isnan(zenith[4])

        batch = liljegren_wbgt_batch(
            air, dew, wind, radiation, time, longitude, latitude;
            direct_fraction = 0.7,
        )
        _assert_matches_scalar(
            batch,
            _scalar_row_results(
                air, dew, wind, radiation, time, longitude, latitude;
                direct_fraction = 0.7,
            ),
        )
        diagnostic = diagnose_liljegren_batch(
            air, dew, wind, radiation, time, longitude, latitude;
            direct_fraction = 0.7,
        )
        @test diagnostic.input_status ==
              [InputAccepted, InputAccepted, MissingTime, InvalidDomain]
    end

    @testset "ordinal AbstractVector indexing and permissive outputs" begin
        air, dew, wind, radiation, time = _batch_inputs()
        offset_air = OffsetArray(air, -2:1)
        offset_dew = OffsetArray(dew, 4:7)
        offset_wind = OffsetArray(wind, 9:12)
        offset_radiation = OffsetArray(radiation, -8:-5)
        offset_time = OffsetArray(time, 20:23)
        longitude = OffsetArray([0.0, 10.0, 0.0, 10.0], 30:33)
        latitude = OffsetArray([-10.0, 0.0, 10.0, 20.0], -20:-17)
        pressure = OffsetArray(fill(1010.0, 4), 40:43)
        direct_fraction = OffsetArray(fill(0.7, 4), -30:-27)
        wbgt = OffsetArray(fill!(Vector{Union{Missing,Float64}}(undef, 4), missing), 100:103)
        wet = OffsetArray(fill!(Vector{Union{Missing,Float64}}(undef, 4), missing), -100:-97)
        globe = OffsetArray(fill!(Vector{Union{Missing,Float64}}(undef, 4), missing), 50:53)
        result = liljegren_wbgt!(
            wbgt, wet, globe, offset_air, offset_dew, offset_wind, offset_radiation, offset_time,
            longitude, latitude; pressure_hpa = pressure, direct_fraction,
        )
        expected = _scalar_row_results(
            offset_air, offset_dew, offset_wind, offset_radiation, offset_time, longitude, latitude;
            pressure_hpa = pressure, direct_fraction,
        )
        _assert_matches_scalar(result, expected)
        @test axes(result.wbgt_c) == axes(wbgt)
        @test axes(result.natural_wet_bulb_c) == axes(wet)
        @test axes(result.globe_temperature_c) == axes(globe)

        any_outputs = (Vector{Any}(undef, 4), Vector{Any}(undef, 4), Vector{Any}(undef, 4))
        any_result = liljegren_wbgt!(any_outputs..., air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
        _assert_matches_scalar(any_result, _scalar_row_results(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7))
        real_outputs = ntuple(_ -> Vector{Union{Missing,Real}}(undef, 4), 3)
        real_result = liljegren_wbgt!(real_outputs..., air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
        _assert_matches_scalar(real_result, _scalar_row_results(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7))
    end

    @testset "pre-mutation input, output, and alias rejection" begin
        air, dew, wind, radiation, time = _batch_inputs()
        wbgt, wet, globe = _sentinel_outputs(4)
        _assert_premutation_failure(() -> liljegren_wbgt!(wbgt[1:3], wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7), wbgt, wet, globe)
        _assert_premutation_failure(() -> liljegren_wbgt!(Vector{Float64}(undef, 4), wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7), wbgt, wet, globe)
        for output_rows in (3, 5, 0)
            wbgt, wet, globe = _sentinel_outputs(output_rows)
            _assert_premutation_failure(
                () -> liljegren_wbgt!(wbgt, wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7),
                wbgt, wet, globe,
            )
        end

        invalid_cases = (
            (Any[30.0, 30.0, 30.0, "bad"], dew, wind, radiation, time, 0.0, 0.0, 1010.0, 0.7),
            (air, dew, wind, radiation, Any[time[1], time[2], time[3], "bad"], 0.0, 0.0, 1010.0, 0.7),
            (air, dew, wind, radiation, time, "bad", 0.0, 1010.0, 0.7),
            (air, dew, wind, radiation, time, 0.0, "bad", 1010.0, 0.7),
            (air, dew, wind, radiation, time, missing, 0.0, 1010.0, 0.7),
            (air, dew, wind, radiation, time, 0.0, missing, 1010.0, 0.7),
            (air, dew, wind, radiation, time, Union{Missing,Float64}[0.0, 0.0, 0.0, missing], 0.0, 1010.0, 0.7),
            (air, dew, wind, radiation, time, 0.0, Union{Missing,Float64}[0.0, 0.0, 0.0, missing], 1010.0, 0.7),
            (air, dew, wind, radiation, time, 0.0, 0.0, Any[1010.0, 1010.0, 1010.0, "bad"], 0.7),
            (air, dew, wind, radiation, time, 0.0, 0.0, 1010.0, Any[0.7, 0.7, 0.7, "bad"]),
            (Real[30, 30, 30, 30], dew, wind, radiation, time, 0.0, 0.0, 1010.0, 0.7),
        )
        for (bad_air, bad_dew, bad_wind, bad_radiation, bad_time, longitude, latitude, pressure, fraction) in invalid_cases
            wbgt, wet, globe = _sentinel_outputs(4)
            _assert_premutation_failure(
                () -> liljegren_wbgt!(wbgt, wet, globe, bad_air, bad_dew, bad_wind, bad_radiation, bad_time, longitude, latitude; pressure_hpa = pressure, direct_fraction = fraction),
                wbgt, wet, globe,
            )
        end

        wbgt, wet, globe = _sentinel_outputs(4)
        _assert_premutation_failure(() -> liljegren_wbgt!(wbgt, wbgt, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7), wbgt, wet, globe)
        aliased_air = fill!(Vector{Union{Missing,Float64}}(undef, 4), 30.0)
        _, wet, globe = _sentinel_outputs(4)
        wbgt = aliased_air
        _assert_premutation_failure(() -> liljegren_wbgt!(wbgt, wet, globe, aliased_air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7), wbgt, wet, globe)
        storage = fill!(Vector{Union{Missing,Float64}}(undef, 6), -999.0)
        overlapping_wbgt, overlapping_wet = @view(storage[1:4]), @view(storage[2:5])
        _assert_premutation_failure(() -> liljegren_wbgt!(overlapping_wbgt, overlapping_wet, globe, air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7), overlapping_wbgt, overlapping_wet, globe)
    end

    @testset "type and missingness equivalence" begin
        cases = (
            (_batch_inputs(), 0.0, 0.0, 1010.0, 0.7, LiljegrenConfig(), Float64),
            (_batch_inputs(float_type = Float32), 0f0, 0f0, 1010f0, 0.7f0, LiljegrenConfig(solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4)), Float32),
            ((BigFloat[30], BigFloat[20], BigFloat[1], BigFloat[800], [DateTime(2024, 6, 21, 12)]), big"0", big"0", big"1010", big"0.7", LiljegrenConfig(), BigFloat),
            ((Union{Missing,Float32}[30, missing], Union{Missing,Float32}[20, 20], Union{Missing,Float32}[1, 1], Union{Missing,Float32}[800, 800], Union{Missing,DateTime}[DateTime(2024, 6, 21, 12), DateTime(2024, 6, 21, 12)]), 0f0, 0f0, 1010f0, 0.7f0, LiljegrenConfig(solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4)), Float32),
        )
        for (inputs, longitude, latitude, pressure, fraction, config, expected_type) in cases
            air, dew, wind, radiation, time = inputs
            batch = liljegren_wbgt_batch(air, dew, wind, radiation, time, longitude, latitude; pressure_hpa = pressure, direct_fraction = fraction, config)
            @test Base.nonmissingtype(eltype(batch.wbgt_c)) === expected_type
            _assert_matches_scalar(batch, _scalar_row_results(air, dew, wind, radiation, time, longitude, latitude; pressure_hpa = pressure, direct_fraction = fraction, config))
        end

        air, dew, wind, radiation, time = _batch_inputs()
        missing_pressure = Union{Missing,Float64}[1010.0, missing, 1010.0, 1010.0]
        missing_fraction = Union{Missing,Float64}[0.7, 0.7, missing, 0.7]
        batch = liljegren_wbgt_batch(air, dew, wind, radiation, time, 0.0, 0.0; pressure_hpa = missing_pressure, direct_fraction = missing_fraction)
        _assert_matches_scalar(batch, _scalar_row_results(air, dew, wind, radiation, time, 0.0, 0.0; pressure_hpa = missing_pressure, direct_fraction = missing_fraction))

        all_missing_air = fill(missing, 4)
        all_missing_batch = liljegren_wbgt_batch(
            all_missing_air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7,
        )
        _assert_matches_scalar(
            all_missing_batch,
            _scalar_row_results(all_missing_air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7),
        )
        all_missing_pressure = fill(missing, 4)
        all_missing_pressure_batch = liljegren_wbgt_batch(
            air, dew, wind, radiation, time, 0.0, 0.0;
            pressure_hpa = all_missing_pressure, direct_fraction = 0.7,
        )
        _assert_matches_scalar(
            all_missing_pressure_batch,
            _scalar_row_results(
                air, dew, wind, radiation, time, 0.0, 0.0;
                pressure_hpa = all_missing_pressure, direct_fraction = 0.7,
            ),
        )

        limited = LiljegrenConfig(solver = SolverConfig(maximum_iterations = 1))
        rejected_and_failed = liljegren_wbgt_batch(
            Union{Missing,Float64}[30.0, missing, -50.0], Union{Missing,Float64}[20.0, 20.0, -50.0],
            Union{Missing,Float64}[1.0, 1.0, 1.0], Union{Missing,Float64}[800.0, 800.0, 800.0],
            Union{Missing,DateTime}[DateTime(2024, 6, 21, 12), DateTime(2024, 6, 21, 12), DateTime(2024, 6, 21, 12)],
            0.0, 0.0; direct_fraction = 0.7, config = limited,
        )
        @test all(ismissing, rejected_and_failed.wbgt_c)
    end

    @testset "complete diagnostic equivalence" begin
        air, dew, wind, radiation, time = _batch_inputs()
        air = Union{Missing,Float64}[air[1], missing, air[3], air[4]]
        time = Union{Missing,DateTime}[time[1], time[2], missing, time[4]]
        serial = diagnose_liljegren_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7)
        threaded = diagnose_liljegren_batch(air, dew, wind, radiation, time, 0.0, 0.0; direct_fraction = 0.7, threaded = true)
        for field in (:input_status, :dew_point_adjusted, :wind_speed_clamped,
                      :solar_radiation_clamped, :solar_geometry_mismatch, :direct_solar_clipped,
                      :threads_available, :rows)
            @test isequal(getproperty(threaded, field), getproperty(serial, field))
        end
        @test isequal(threaded.result.wbgt_c, serial.result.wbgt_c)
        @test isequal(threaded.result.natural_wet_bulb_c, serial.result.natural_wet_bulb_c)
        @test isequal(threaded.result.globe_temperature_c, serial.result.globe_temperature_c)
        @test threaded.threaded
        @test !serial.threaded
        _assert_component_diagnostics_equal(threaded.globe, serial.globe)
        _assert_component_diagnostics_equal(threaded.natural_wet_bulb, serial.natural_wet_bulb)
    end

    @testset "independent scalar fixtures" begin
        fixture_data = TOML.parsefile(joinpath(@__DIR__, "fixtures", "liljegren_scalar_reference.toml"))
        fixtures = collect(values(fixture_data["fixtures"]))
        fixture_air = [fixture["air_temperature_c"] for fixture in fixtures]
        fixture_dew = [fixture["dew_point_c"] for fixture in fixtures]
        fixture_wind = [fixture["wind_speed_m_s"] for fixture in fixtures]
        fixture_radiation = [fixture["solar_radiation_w_m2"] for fixture in fixtures]
        fixture_time = DateTime[DateTime(fixture["time"]) for fixture in fixtures]
        fixture_longitude = [fixture["longitude_deg"] for fixture in fixtures]
        fixture_latitude = [fixture["latitude_deg"] for fixture in fixtures]
        fixture_pressure = [fixture["pressure_hpa"] for fixture in fixtures]
        fixture_direct_fraction = [fixture["direct_fraction"] for fixture in fixtures]
        serial = liljegren_wbgt_batch(fixture_air, fixture_dew, fixture_wind, fixture_radiation, fixture_time, fixture_longitude, fixture_latitude; pressure_hpa = fixture_pressure, direct_fraction = fixture_direct_fraction)
        threaded = liljegren_wbgt_batch(fixture_air, fixture_dew, fixture_wind, fixture_radiation, fixture_time, fixture_longitude, fixture_latitude; pressure_hpa = fixture_pressure, direct_fraction = fixture_direct_fraction, threaded = true)
        for row in eachindex(fixtures)
            fixture = fixtures[row]
            @test serial.globe_temperature_c[row] ≈ parse(Float64, fixture["globe_temperature_c"]) atol = 1e-4 rtol = 1e-8
            @test serial.natural_wet_bulb_c[row] ≈ parse(Float64, fixture["natural_wet_bulb_c"]) atol = 1e-4 rtol = 1e-8
            @test serial.wbgt_c[row] ≈ parse(Float64, fixture["wbgt_c"]) atol = 1e-4 rtol = 1e-8
        end
        @test threaded.wbgt_c == serial.wbgt_c
    end
end
