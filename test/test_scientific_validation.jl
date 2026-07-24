using CSV
using Dates: DateTime
using Test

const _VALIDATION_ROOT = normpath(joinpath(@__DIR__, "..", "validation"))
const _VALIDATION_FIXTURES = joinpath(_VALIDATION_ROOT, "fixtures")

_fixture(name) = CSV.File(joinpath(_VALIDATION_FIXTURES, name))
_status(name::AbstractString) = getproperty(HeatStress, Symbol(name))

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

    @testset "Liljegren high-precision references and residuals" begin
        rows = collect(_fixture("liljegren_reference.csv"))
        diagnostics = [
            diagnose_liljegren(
                row.air_temperature_c, row.dew_point_c, row.wind_speed_m_s,
                row.solar_radiation_w_m2, DateTime(row.time), row.longitude_deg, row.latitude_deg;
                pressure_hpa = row.pressure_hpa, direct_fraction = row.direct_fraction,
            ) for row in rows
        ]
        for (row, diagnostic) in zip(rows, diagnostics)
            @test diagnostic.input_status === InputAccepted
            @test diagnostic.result.globe_temperature_c ≈ row.expected_globe_c atol = row.atol_c
            @test diagnostic.result.natural_wet_bulb_c ≈ row.expected_natural_wet_bulb_c atol = row.atol_c
            @test diagnostic.result.wbgt_c ≈ row.expected_wbgt_c atol = row.atol_c
            @test abs(diagnostic.globe.validation_residual_k) <= diagnostic.globe.residual_tolerance_k
            @test abs(diagnostic.natural_wet_bulb.validation_residual_k) <= diagnostic.natural_wet_bulb.residual_tolerance_k
        end

        # Fixed-coordinate, grouped-coordinate, and unique-coordinate batch
        # paths must retain row order, values, statuses, and diagnostics.
        air = getproperty.(rows, :air_temperature_c)
        dew = getproperty.(rows, :dew_point_c)
        wind = getproperty.(rows, :wind_speed_m_s)
        radiation = getproperty.(rows, :solar_radiation_w_m2)
        time = DateTime.(getproperty.(rows, :time))
        pressure = getproperty.(rows, :pressure_hpa)
        direct = getproperty.(rows, :direct_fraction)
        scalar_reference = getproperty.(getproperty.(diagnostics, :result), :wbgt_c)
        fixed = liljegren_wbgt_batch(air, dew, wind, radiation, time, 0.0, 0.0; pressure_hpa = pressure, direct_fraction = direct)
        grouped = liljegren_wbgt_batch(air, dew, wind, radiation, time, [0.0, 0.0, 10.0, 10.0], [0.0, 0.0, 0.0, 0.0]; pressure_hpa = pressure, direct_fraction = direct)
        unique = liljegren_wbgt_batch(air, dew, wind, radiation, time, [0.0, 0.0, 1.0, 2.0], [0.0, 0.0, 1.0, 2.0]; pressure_hpa = pressure, direct_fraction = direct, threaded = true)
        @test fixed.wbgt_c == scalar_reference
        @test all(!ismissing, grouped.wbgt_c)
        @test all(!ismissing, unique.wbgt_c)
        diagnosed = diagnose_liljegren_batch(air, dew, wind, radiation, time, 0.0, 0.0; pressure_hpa = pressure, direct_fraction = direct, threaded = true)
        @test diagnosed.input_status == fill(InputAccepted, length(rows))
        @test diagnosed.result.wbgt_c == fixed.wbgt_c

        config32 = LiljegrenConfig(solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4), dew_point_tolerance_c = 1f-4)
        float32 = liljegren_wbgt_batch(Float32.(air), Float32.(dew), Float32.(wind), Float32.(radiation), time, 0f0, 0f0; pressure_hpa = Float32.(pressure), direct_fraction = Float32.(direct), config = config32)
        @test all(abs.(Float64.(float32.wbgt_c) .- Float64.(fixed.wbgt_c)) .<= 2e-3)
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
            ismissing(diagnostic.result.wbgt_c) && @test true
        end
    end
end
