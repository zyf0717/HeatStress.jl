using CSV
using Dates: DateTime
using Test

const _VALIDATION_ROOT = normpath(joinpath(@__DIR__, "..", "validation"))
const _VALIDATION_FIXTURES = joinpath(_VALIDATION_ROOT, "fixtures")

_fixture(name) = CSV.File(joinpath(_VALIDATION_FIXTURES, name))
_status(name::AbstractString) = getproperty(HeatStress, Symbol(name))

function _coordinate_modes(rows)
    count = length(rows)
    grouped_longitude = [isodd(index) ? 0.0 : 10.0 for index in 1:count]
    grouped_latitude = [isodd(index) ? 0.0 : 5.0 for index in 1:count]
    unique_longitude = [Float64(index - 1) for index in 1:count]
    unique_latitude = [Float64(1 - index) for index in 1:count]
    return (
        fixed = (0.0, 0.0),
        grouped = (grouped_longitude, grouped_latitude),
        unique = (unique_longitude, unique_latitude),
    )
end

function _assert_component_batch_matches(component_batch, scalar_components)
    for field in fieldnames(SolverDiagnosticsBatch)
        @test getfield(component_batch, field) == getfield.(scalar_components, field)
    end
end

function _assert_diagnostic_batch_matches(batch, scalar, threaded::Bool)
    @test batch.rows == length(scalar)
    @test batch.threaded === threaded
    @test batch.threads_available == Threads.nthreads()
    for field in fieldnames(WBGTResult)
        @test getfield(batch.result, field) == getfield.(getproperty.(scalar, :result), field)
    end
    for field in (
        :input_status,
        :dew_point_adjusted,
        :wind_speed_clamped,
        :solar_radiation_clamped,
        :solar_geometry_mismatch,
        :direct_solar_clipped,
    )
        @test getfield(batch, field) == getfield.(scalar, field)
    end
    _assert_component_batch_matches(batch.globe, getproperty.(scalar, :globe))
    _assert_component_batch_matches(batch.natural_wet_bulb, getproperty.(scalar, :natural_wet_bulb))
end

function _maximum_error(label, errors, identifiers)
    maximum_error, index = findmax(errors)
    if maximum_error > 0
        @info "scientific validation maximum difference" family = label id = identifiers[index] error = maximum_error
    end
    return maximum_error
end

@testset "scientific validation corpus" begin
    @test isfile(joinpath(_VALIDATION_ROOT, "metadata", "fixture-set-v1.toml"))

    @testset "solar and psychrometric fixtures" begin
        solar_rows = collect(_fixture("solar_geometry.csv"))
        solar_errors = [
            abs(solar_zenith(DateTime(row.time), row.longitude_deg, row.latitude_deg) - row.expected_zenith_deg)
            for row in solar_rows
        ]
        @test _maximum_error("solar geometry", solar_errors, getproperty.(solar_rows, :id)) <=
              maximum(getproperty.(solar_rows, :atol_deg))

        for row in _fixture("psychrometrics.csv")
            @test saturation_vapour_pressure_hpa(row.air_temperature_c) ≈ row.expected_saturation_hpa rtol = row.rtol
            @test vapour_pressure(row.air_temperature_c, row.relative_humidity_percent) ≈ row.expected_actual_hpa rtol = row.rtol
            @test relative_humidity_from_dewpoint(row.air_temperature_c, row.dew_point_c) ≈
                  row.relative_humidity_percent rtol = row.rtol
            @test relative_humidity_from_dewpoint(row.air_temperature_c, row.air_temperature_c) ≈ 100.0 atol = eps()
        end
    end

    @testset "physical-kernel fixtures" begin
        for row in _fixture("physical_kernels.csv")
            @test HeatStress._air_viscosity(row.temperature_k) ≈ row.expected_viscosity_pa_s rtol = row.rtol
            @test HeatStress._air_thermal_conductivity(row.temperature_k) ≈ row.expected_conductivity_w_mk rtol = row.rtol
            @test HeatStress._air_diffusivity(row.temperature_k, row.pressure_hpa) ≈ row.expected_diffusivity_m2_s rtol = row.rtol
        end
    end

    @testset "secondary-measure fixtures" begin
        @test isfile(joinpath(_VALIDATION_ROOT, "metadata", "fixture-set-v2.toml"))
        rows = collect(_fixture("simple_indices.csv"))
        values = map(rows) do row
            if row.formula == "wbgt_with_solar_load"
                wbgt_with_solar_load(
                    row.natural_wet_bulb_c,
                    row.globe_temperature_c,
                    row.dry_bulb_temperature_c,
                )
            elseif row.formula == "wbgt_without_solar_load"
                wbgt_without_solar_load(
                    row.natural_wet_bulb_c,
                    row.globe_temperature_c,
                )
            elseif row.formula == "heat_index_nws"
                heat_index_nws(row.air_temperature_c, row.relative_humidity_percent)
            elseif row.formula == "wet_bulb_temperature_stull"
                wet_bulb_temperature_stull(
                    row.air_temperature_c,
                    row.relative_humidity_percent,
                )
            elseif row.formula == "humidex"
                humidex(row.air_temperature_c, row.dew_point_c)
            else
                error("unsupported simple-index fixture formula: $(row.formula)")
            end
        end
        errors = abs.(values .- getproperty.(rows, :expected_value))
        _maximum_error("secondary measures", errors, getproperty.(rows, :id))
        @test all(
            error <= row.atol + row.rtol * abs(row.expected_value)
            for (error, row) in zip(errors, rows)
        )
    end

    @testset "Liljegren high-precision references and residuals" begin
        rows = collect(_fixture("liljegren_reference.csv"))
        reference_diagnostics = [
            diagnose_liljegren(
                row.air_temperature_c, row.dew_point_c, row.wind_speed_m_s,
                row.solar_radiation_w_m2, DateTime(row.time), row.longitude_deg, row.latitude_deg;
                pressure_hpa = row.pressure_hpa, direct_fraction = row.direct_fraction,
            ) for row in rows
        ]
        for (row, diagnostic) in zip(rows, reference_diagnostics)
            @test diagnostic.input_status === InputAccepted
            @test diagnostic.result.globe_temperature_c ≈ row.expected_globe_c atol = row.atol_c
            @test diagnostic.result.natural_wet_bulb_c ≈ row.expected_natural_wet_bulb_c atol = row.atol_c
            @test diagnostic.result.wbgt_c ≈ row.expected_wbgt_c atol = row.atol_c
            @test abs(diagnostic.globe.validation_residual_k) <= diagnostic.globe.residual_tolerance_k
            @test abs(diagnostic.natural_wet_bulb.validation_residual_k) <= diagnostic.natural_wet_bulb.residual_tolerance_k
        end

        # Fixed-coordinate, grouped-coordinate, and unique-coordinate batches
        # must agree exactly with scalar calls using each row's coordinates.
        air = getproperty.(rows, :air_temperature_c)
        dew = getproperty.(rows, :dew_point_c)
        wind = getproperty.(rows, :wind_speed_m_s)
        radiation = getproperty.(rows, :solar_radiation_w_m2)
        time = DateTime.(getproperty.(rows, :time))
        pressure = getproperty.(rows, :pressure_hpa)
        direct = getproperty.(rows, :direct_fraction)
        for (mode, (longitude, latitude)) in pairs(_coordinate_modes(rows))
            scalar = [
                diagnose_liljegren(
                    air[index], dew[index], wind[index], radiation[index], time[index],
                    longitude isa AbstractVector ? longitude[index] : longitude,
                    latitude isa AbstractVector ? latitude[index] : latitude;
                    pressure_hpa = pressure[index], direct_fraction = direct[index],
                ) for index in eachindex(air)
            ]
            for threaded in (false, true)
                value = liljegren_wbgt_batch(
                    air, dew, wind, radiation, time, longitude, latitude;
                    pressure_hpa = pressure, direct_fraction = direct, threaded,
                )
                @test value.wbgt_c == getproperty.(getproperty.(scalar, :result), :wbgt_c)
                @test value.natural_wet_bulb_c == getproperty.(getproperty.(scalar, :result), :natural_wet_bulb_c)
                @test value.globe_temperature_c == getproperty.(getproperty.(scalar, :result), :globe_temperature_c)
                diagnostic = diagnose_liljegren_batch(
                    air, dew, wind, radiation, time, longitude, latitude;
                    pressure_hpa = pressure, direct_fraction = direct, threaded,
                )
                _assert_diagnostic_batch_matches(diagnostic, scalar, threaded)
            end
        end

        config32 = LiljegrenConfig(solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4), dew_point_tolerance_c = 1f-4)
        float32 = liljegren_wbgt_batch(Float32.(air), Float32.(dew), Float32.(wind), Float32.(radiation), time, 0f0, 0f0; pressure_hpa = Float32.(pressure), direct_fraction = Float32.(direct), config = config32)
        reference_values = getproperty.(getproperty.(reference_diagnostics, :result), :wbgt_c)
        @test all(abs.(Float64.(float32.wbgt_c) .- Float64.(reference_values)) .<= 2e-3)
    end

    @testset "failure fixtures" begin
        for row in _fixture("liljegren_failures.csv")
            diagnostic = diagnose_liljegren(
                row.air_temperature_c, row.dew_point_c, row.wind_speed_m_s,
                row.solar_radiation_w_m2, DateTime(row.time), row.longitude_deg, row.latitude_deg;
                pressure_hpa = row.pressure_hpa, direct_fraction = row.direct_fraction,
            )
            @test diagnostic.input_status === _status(row.expected_input_status)
            @test diagnostic.globe.reason === _status(row.expected_globe_reason)
            @test diagnostic.natural_wet_bulb.reason === _status(row.expected_wet_bulb_reason)
            @test ismissing(diagnostic.result.wbgt_c)
            if row.id == "partial_unbracketed"
                @test ismissing(diagnostic.result.globe_temperature_c)
                @test !ismissing(diagnostic.result.natural_wet_bulb_c)
            else
                @test ismissing(diagnostic.result.globe_temperature_c)
                @test ismissing(diagnostic.result.natural_wet_bulb_c)
            end
        end
    end

    @testset "reference fixture regeneration" begin
        generator = joinpath(_VALIDATION_ROOT, "generate_validation_cases.jl")
        include(generator)
        @test ValidationReferenceGenerator.reference_matches()
        simple_generator = joinpath(_VALIDATION_ROOT, "generate_simple_indices.jl")
        include(simple_generator)
        @test SimpleIndexReferenceGenerator.fixture_matches()
    end
end
