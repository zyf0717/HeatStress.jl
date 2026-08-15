using CSV
using Dates: DateTime
using SHA
using TOML
using Test

const _V3_VALIDATION_ROOT = normpath(joinpath(@__DIR__, "..", "validation"))
const _V3_FIXTURE_ROOT = joinpath(_V3_VALIDATION_ROOT, "fixtures", "v3")

_v3_fixture(name) = collect(CSV.File(joinpath(_V3_FIXTURE_ROOT, name)))
_v3_status(name::AbstractString) = getproperty(HeatStress, Symbol(name))

function _v3_close(family, row, actual, expected; atol, rtol = 0)
    passed = isapprox(actual, expected; atol, rtol)
    if !passed
        @error "fixture-set-v3 mismatch" family id = row.id authority = row.authority source_id = row.source_id inputs = NamedTuple(row) expected actual absolute_error = abs(actual - expected) permitted_atol = atol permitted_rtol = rtol
    end
    @test passed
    return abs(actual - expected)
end

function _v3_equal(family, row, actual, expected)
    passed = isequal(actual, expected)
    if !passed
        @error "fixture-set-v3 status mismatch" family id = row.id authority = row.authority source_id = row.source_id inputs = NamedTuple(row) expected actual
    end
    @test passed
    return nothing
end

function _v3_halton(index::Int, base::Int)
    result = 0.0
    factor = 1.0
    value = index
    while value > 0
        factor /= base
        result += factor * (value % base)
        value ÷= base
    end
    return result
end

function _v3_property_inputs(rows::Int)
    geometries = (
        (DateTime(2024, 3, 20, 12), 0.0, 0.0),
        (DateTime(2024, 3, 20, 0), 0.0, 0.0),
        (DateTime(2024, 12, 21, 15), 0.0, 45.0),
        (DateTime(2024, 6, 21, 18), -21.9426, 64.1466),
    )
    air = Vector{Float64}(undef, rows)
    dew = similar(air)
    wind = similar(air)
    radiation = similar(air)
    pressure = similar(air)
    direct = similar(air)
    time = Vector{DateTime}(undef, rows)
    longitude = similar(air)
    latitude = similar(air)
    for index in 1:rows
        air[index] = -40 + 90 * _v3_halton(index, 2)
        dew[index] = -40 + (air[index] + 40) * _v3_halton(index, 3)
        wind[index] = 10 * _v3_halton(index, 5)
        radiation[index] = 1200 * _v3_halton(index, 7)
        pressure[index] = 700 + 400 * _v3_halton(index, 11)
        direct[index] = _v3_halton(index, 13)
        geometry = geometries[1 + floor(Int, 4 * _v3_halton(index, 17))]
        time[index], longitude[index], latitude[index] = geometry
    end
    return (; air, dew, wind, radiation, time, longitude, latitude, pressure, direct)
end

function _v3_assert_component_invariants(component)
    if component.converged
        @test !ismissing(component.value_c)
        @test !ismissing(component.candidate_c)
        @test component.final_lower_k <= component.candidate_c + HeatStress.KELVIN_OFFSET <=
              component.final_upper_k
        @test isfinite(component.validation_residual_k)
        @test abs(component.validation_residual_k) <= component.residual_tolerance_k
    else
        @test ismissing(component.value_c)
    end
end

@testset "fixture-set-v3 numerical conformance" begin
    @testset "metadata, provenance, schema, and covering array" begin
        metadata_path = joinpath(_V3_VALIDATION_ROOT, "metadata", "fixture-set-v3.toml")
        metadata = TOML.parsefile(metadata_path)
        @test metadata["schema_version"] == 4
        @test metadata["generator_revision"] == "v2-buck-liljegren"
        @test metadata["precision_bits"] == 256
        @test metadata["liljegren_reference_rows"] == 64
        for record in values(metadata["files"])
            path = normpath(joinpath(@__DIR__, "..", record["path"]))
            @test isfile(path)
            @test bytes2hex(sha256(read(path))) == record["sha256"]
        end

        sources = Set(keys(TOML.parsefile(
            joinpath(_V3_VALIDATION_ROOT, "sources.toml"),
        )["sources"]))
        families = (
            "liljegren_reference.csv", "liljegren_components.csv",
            "liljegren_failures.csv", "solar_geometry.csv",
            "psychrometrics.csv", "physical_kernels.csv",
            "secondary_indices.csv",
        )
        for family in families
            rows = _v3_fixture(family)
            @test length(unique(getproperty.(rows, :id))) == length(rows)
            @test all(row.source_id in sources for row in rows)
            @test all(hasproperty(row, :authority) for row in rows)
            @test all(hasproperty(row, :atol) || hasproperty(row, :atol_c) ||
                      hasproperty(row, :atol_deg) for row in rows)
            @test all(hasproperty(row, :rtol) for row in rows)
        end

        rows = _v3_fixture("liljegren_reference.csv")
        @test length(rows) == 64
        components = _v3_fixture("liljegren_components.csv")
        @test getproperty.(components, :id) == getproperty.(rows[1:16], :id)
        for component in components
            @test component.expected_globe_reason == "NoFailure"
            @test component.expected_globe_lower_k - component.atol_c <=
                  component.expected_globe_c + HeatStress.KELVIN_OFFSET <=
                  component.expected_globe_upper_k + component.atol_c
            @test isfinite(component.expected_globe_residual)
            if component.expected_wet_bulb_reason == "NoFailure"
                @test component.expected_wet_lower_k - component.atol_c <=
                      component.expected_natural_wet_bulb_c + HeatStress.KELVIN_OFFSET <=
                      component.expected_wet_upper_k + component.atol_c
                @test isfinite(component.expected_wet_bulb_residual)
            else
                @test component.expected_wet_bulb_reason == "Unbracketed"
                @test ismissing(component.expected_natural_wet_bulb_c)
                @test component.expected_wet_lower_k >=
                      HeatStress.KELVIN_OFFSET + HeatStress.BUCK_MINIMUM_TEMPERATURE_C
                @test component.expected_wet_upper_k <=
                      HeatStress.KELVIN_OFFSET + HeatStress.BUCK_MAXIMUM_TEMPERATURE_C
            end
        end
        factor_names = (
            :air_factor, :dew_factor, :wind_factor, :radiation_factor,
            :pressure_factor, :direct_factor, :geometry_factor,
        )
        for left in 1:6, right in (left + 1):7
            observed = Set(
                (getproperty(row, factor_names[left]), getproperty(row, factor_names[right]))
                for row in rows
            )
            @test observed == Set(Iterators.product(0:3, 0:3))
        end
    end

    @testset "expanded source-level fixtures" begin
        solar_rows = _v3_fixture("solar_geometry.csv")
        solar_errors = Float64[]
        for row in solar_rows
            actual = solar_zenith(
                DateTime(row.time),
                row.longitude_deg,
                row.latitude_deg,
            )
            push!(solar_errors, _v3_close(
                "solar_geometry",
                row,
                actual,
                row.expected_zenith_deg;
                atol = row.atol_deg,
                rtol = row.rtol,
            ))
        end
        worst_error, worst_index = findmax(solar_errors)
        @info "fixture-set-v3 maximum difference" family = "solar_geometry" id = solar_rows[worst_index].id error = worst_error inputs = NamedTuple(solar_rows[worst_index])

        for row in _v3_fixture("psychrometrics.csv")
            saturation = saturation_vapour_pressure_hpa(row.air_temperature_c)
            actual = vapour_pressure(
                row.air_temperature_c,
                row.relative_humidity_percent,
            )
            _v3_close("psychrometrics/saturation", row, saturation,
                row.expected_saturation_hpa; atol = row.atol, rtol = row.rtol)
            _v3_close("psychrometrics/actual", row, actual,
                row.expected_actual_hpa; atol = row.atol, rtol = row.rtol)
        end

        for row in _v3_fixture("physical_kernels.csv")
            _v3_close("physical/viscosity", row,
                HeatStress._air_viscosity(row.temperature_k),
                row.expected_viscosity_pa_s; atol = row.atol, rtol = row.rtol)
            _v3_close("physical/conductivity", row,
                HeatStress._air_thermal_conductivity(row.temperature_k),
                row.expected_conductivity_w_mk; atol = row.atol, rtol = row.rtol)
            _v3_close("physical/diffusivity", row,
                HeatStress._air_diffusivity(row.temperature_k, row.pressure_hpa),
                row.expected_diffusivity_m2_s; atol = row.atol, rtol = row.rtol)
            _v3_close("physical/density", row,
                HeatStress._air_density(row.temperature_k, row.pressure_hpa),
                row.expected_density_kg_m3; atol = row.atol, rtol = row.rtol)
            _v3_close("physical/emissivity", row,
                HeatStress._atmospheric_emissivity(row.vapour_pressure_hpa),
                row.expected_emissivity; atol = row.atol, rtol = row.rtol)
            _v3_close("physical/sphere_convection", row,
                HeatStress._heat_transfer_sphere_air(
                    row.temperature_k,
                    row.pressure_hpa,
                    row.wind_speed_m_s,
                    HeatStress.DEFAULT_GLOBE_DIAMETER_M,
                ),
                row.expected_sphere_convection_w_m2k;
                atol = row.atol,
                rtol = row.rtol,
            )
            _v3_close("physical/cylinder_convection", row,
                HeatStress._heat_transfer_cylinder_air(
                    row.temperature_k,
                    row.pressure_hpa,
                    row.wind_speed_m_s,
                    HeatStress.WICK_DIAMETER_M,
                ),
                row.expected_cylinder_convection_w_m2k;
                atol = row.atol,
                rtol = row.rtol,
            )
            _v3_close("physical/latent_heat", row,
                HeatStress._latent_heat_vaporization(row.temperature_k),
                row.expected_latent_heat_j_kg;
                atol = row.atol,
                rtol = row.rtol,
            )
        end

        for row in _v3_fixture("secondary_indices.csv")
            actual = if row.formula == "wbgt_with_solar_load"
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
            else
                humidex(row.air_temperature_c, row.dew_point_c)
            end
            _v3_close("secondary_indices", row, actual, row.expected_value;
                atol = row.atol, rtol = row.rtol)
        end
    end

    @testset "64-case Liljegren reference matrix" begin
        rows = _v3_fixture("liljegren_reference.csv")
        diagnostics = map(rows) do row
            _compat_diagnose_liljegren(
                row.air_temperature_c,
                row.dew_point_c,
                row.wind_speed_m_s,
                row.solar_radiation_w_m2,
                DateTime(row.time),
                row.longitude_deg,
                row.latitude_deg;
                pressure_hpa = row.pressure_hpa,
                direct_fraction = row.direct_fraction,
            )
        end
        for (row, diagnostic) in zip(rows, diagnostics)
            _v3_equal("liljegren/input", row, diagnostic.input_status,
                _v3_status(row.expected_input_status))
            _v3_equal("liljegren/globe_status", row, diagnostic.globe.reason,
                _v3_status(row.expected_globe_reason))
            _v3_equal("liljegren/wet_status", row, diagnostic.natural_wet_bulb.reason,
                _v3_status(row.expected_wet_bulb_reason))
            if row.expected_globe_reason == "NoFailure"
                _v3_close("liljegren/globe", row,
                    diagnostic.result.globe_temperature_c, row.expected_globe_c;
                    atol = row.atol_c, rtol = row.rtol)
            else
                @test ismissing(diagnostic.result.globe_temperature_c)
            end
            if row.expected_wet_bulb_reason == "NoFailure"
                _v3_close("liljegren/wet", row,
                    diagnostic.result.natural_wet_bulb_c,
                    row.expected_natural_wet_bulb_c;
                    atol = row.atol_c, rtol = row.rtol)
            else
                @test ismissing(diagnostic.result.natural_wet_bulb_c)
            end
            _v3_assert_component_invariants(diagnostic.globe)
            _v3_assert_component_invariants(diagnostic.natural_wet_bulb)
            if row.expected_globe_reason == "NoFailure" &&
               row.expected_wet_bulb_reason == "NoFailure"
                _v3_close("liljegren/wbgt", row,
                    diagnostic.result.wbgt_c, row.expected_wbgt_c;
                    atol = row.atol_c, rtol = row.rtol)
                @test diagnostic.result.wbgt_c ≈
                      0.7 * diagnostic.result.natural_wet_bulb_c +
                      0.2 * diagnostic.result.globe_temperature_c +
                      0.1 * row.air_temperature_c atol = 2eps(Float64)
            else
                @test ismissing(diagnostic.result.wbgt_c)
            end
        end

        air = getproperty.(rows, :air_temperature_c)
        dew = getproperty.(rows, :dew_point_c)
        wind = getproperty.(rows, :wind_speed_m_s)
        radiation = getproperty.(rows, :solar_radiation_w_m2)
        time = DateTime.(getproperty.(rows, :time))
        longitude = getproperty.(rows, :longitude_deg)
        latitude = getproperty.(rows, :latitude_deg)
        pressure = getproperty.(rows, :pressure_hpa)
        direct = getproperty.(rows, :direct_fraction)
        expected_wbgt = getproperty.(getproperty.(diagnostics, :result), :wbgt_c)
        expected_wet = getproperty.(getproperty.(diagnostics, :result), :natural_wet_bulb_c)
        expected_globe = getproperty.(getproperty.(diagnostics, :result), :globe_temperature_c)

        for threaded in (false, true)
            batch = _compat_liljegren_wbgt_batch(
                air, dew, wind, radiation, time, longitude, latitude;
                pressure_hpa = pressure,
                direct_fraction = direct,
                threaded,
            )
            @test isequal(batch.wbgt_c, expected_wbgt)
            @test isequal(batch.natural_wet_bulb_c, expected_wet)
            @test batch.globe_temperature_c == expected_globe
            diagnostic_batch = _compat_diagnose_liljegren_batch(
                air, dew, wind, radiation, time, longitude, latitude;
                pressure_hpa = pressure,
                direct_fraction = direct,
                threaded,
            )
            @test diagnostic_batch.input_status == getproperty.(diagnostics, :input_status)
            @test isequal(diagnostic_batch.result.wbgt_c, expected_wbgt)
        end

        outputs = (
            Vector{Union{Missing,Float64}}(undef, length(rows)),
            Vector{Union{Missing,Float64}}(undef, length(rows)),
            Vector{Union{Missing,Float64}}(undef, length(rows)),
        )
        preallocated = _compat_liljegren_wbgt!(
            outputs...,
            air, dew, wind, radiation, time, longitude, latitude;
            pressure_hpa = pressure,
            direct_fraction = direct,
        )
        @test isequal(preallocated.wbgt_c, expected_wbgt)
        @test isequal(preallocated.natural_wet_bulb_c, expected_wet)
        @test preallocated.globe_temperature_c == expected_globe

        tighter = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1e-7, residual_tolerance_k = 1e-5),
        )
        tighter_values = _compat_liljegren_wbgt_batch(
            air, dew, wind, radiation, time, longitude, latitude;
            pressure_hpa = pressure,
            direct_fraction = direct,
            config = tighter,
        )
        for index in eachindex(expected_wbgt)
            if ismissing(expected_wbgt[index])
                @test ismissing(tighter_values.wbgt_c[index])
            else
                @test abs(tighter_values.wbgt_c[index] - expected_wbgt[index]) <= 5e-4
            end
        end

        config32 = LiljegrenConfig(
            solver = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4),
            dew_point_tolerance_c = 1f-4,
        )
        diagnostics32 = _compat_diagnose_liljegren_batch(
            Float32.(air), Float32.(dew), Float32.(wind), Float32.(radiation),
            time, Float32.(longitude), Float32.(latitude);
            pressure_hpa = Float32.(pressure),
            direct_fraction = Float32.(direct),
            config = config32,
        )
        @test diagnostics32.input_status == getproperty.(diagnostics, :input_status)
        float32_expected_reasons = Dict(
            "liljegren_v3_004" => (globe = ResidualValidationFailed, wet = NoFailure),
            "liljegren_v3_040" => (globe = ResidualValidationFailed, wet = NoFailure),
            "liljegren_v3_047" => (
                globe = ResidualValidationFailed,
                wet = ResidualValidationFailed,
            ),
            "liljegren_v3_061" => (globe = ResidualValidationFailed, wet = NoFailure),
        )
        for (index, row) in enumerate(rows)
            globe_reason = diagnostics32.globe.reason[index]
            wet_reason = diagnostics32.natural_wet_bulb.reason[index]
            expected_reasons = get(
                float32_expected_reasons,
                row.id,
                (
                    globe = diagnostics[index].globe.reason,
                    wet = diagnostics[index].natural_wet_bulb.reason,
                ),
            )
            @test globe_reason === expected_reasons.globe
            @test wet_reason === expected_reasons.wet
            if ismissing(expected_wbgt[index]) || globe_reason !== NoFailure ||
               wet_reason !== NoFailure
                @test ismissing(diagnostics32.result.wbgt_c[index])
            else
                @test abs(
                    Float64(diagnostics32.result.wbgt_c[index]) - expected_wbgt[index],
                ) <= 2e-3
            end
            if !ismissing(diagnostics32.result.globe_temperature_c[index])
                @test abs(
                    Float64(diagnostics32.result.globe_temperature_c[index]) -
                    expected_globe[index],
                ) <= 2e-3
            end
            if !ismissing(diagnostics32.result.natural_wet_bulb_c[index])
                @test abs(
                    Float64(diagnostics32.result.natural_wet_bulb_c[index]) -
                    expected_wet[index],
                ) <= 2e-3
            end
        end
    end

    @testset "failure taxonomy" begin
        rows = Dict(row.id => row for row in _v3_fixture("liljegren_failures.csv"))
        ordinary = (
            30.0, 20.0, 1.0, 800.0, DateTime(2024, 6, 21, 12), 0.0, 0.0,
        )
        public_cases = Dict(
            "missing_meteorology" => _compat_diagnose_liljegren(
                missing, ordinary[2:end]...; pressure_hpa = 1010.0, direct_fraction = 0.7,
            ),
            "missing_time" => _compat_diagnose_liljegren(
                ordinary[1:4]..., missing, ordinary[6:7]...;
                pressure_hpa = 1010.0, direct_fraction = 0.7,
            ),
            "invalid_dew_point" => _compat_diagnose_liljegren(
                20.0, 25.0, ordinary[3:end]...;
                pressure_hpa = 1010.0,
                direct_fraction = 0.7,
                config = LiljegrenConfig(dew_point_policy = RejectInvalidDewPoint),
            ),
            "invalid_domain" => _compat_diagnose_liljegren(
                ordinary...; pressure_hpa = 0.0, direct_fraction = 0.7,
            ),
        )
        for (id, diagnostic) in public_cases
            row = rows[id]
            @test diagnostic.input_status === _v3_status(row.expected_input_status)
            @test diagnostic.globe.reason === _v3_status(row.expected_failure_reason)
            @test diagnostic.natural_wet_bulb.reason === _v3_status(row.expected_failure_reason)
        end

        config = SolverConfig()
        successful = HeatStress._solve_bracketed(
            value -> value - 0.25,
            0.0, 1.0, HeatStress._GlobeBracketExpansion(), 0.0, 1.0, config,
        )
        solver_reasons = Dict(
            "no_failure" => HeatStress._solver_diagnostics(successful, 0.0, config).reason,
            "residual_validation_failed" =>
                HeatStress._solver_diagnostics(successful, 1.0, config).reason,
            "unbracketed" => HeatStress._solve_bracketed(
                _ -> 1.0, 0.0, 1.0, HeatStress._GlobeBracketExpansion(), 0.0, 1.0, config,
            ).reason,
            "nonfinite_residual" => HeatStress._solve_bracketed(
                _ -> NaN, 0.0, 1.0, HeatStress._GlobeBracketExpansion(), 0.0, 1.0, config,
            ).reason,
            "iteration_limit" => HeatStress._solve_bracketed(
                value -> value - 0.2,
                0.0, 1.0, HeatStress._GlobeBracketExpansion(), 0.0, 1.0,
                SolverConfig(maximum_iterations = 1),
            ).reason,
            "not_attempted" => public_cases["invalid_domain"].globe.reason,
        )
        for (id, actual) in solver_reasons
            @test actual === _v3_status(rows[id].expected_failure_reason)
        end
    end

    @testset "256 deterministic accepted-domain properties" begin
        inputs = _v3_property_inputs(256)
        scalar = [
            _compat_diagnose_liljegren(
                inputs.air[index], inputs.dew[index], inputs.wind[index],
                inputs.radiation[index], inputs.time[index],
                inputs.longitude[index], inputs.latitude[index];
                pressure_hpa = inputs.pressure[index],
                direct_fraction = inputs.direct[index],
            )
            for index in eachindex(inputs.air)
        ]
        serial = _compat_diagnose_liljegren_batch(
            inputs.air, inputs.dew, inputs.wind, inputs.radiation, inputs.time,
            inputs.longitude, inputs.latitude;
            pressure_hpa = inputs.pressure,
            direct_fraction = inputs.direct,
            threaded = false,
        )
        threaded = _compat_diagnose_liljegren_batch(
            inputs.air, inputs.dew, inputs.wind, inputs.radiation, inputs.time,
            inputs.longitude, inputs.latitude;
            pressure_hpa = inputs.pressure,
            direct_fraction = inputs.direct,
            threaded = true,
        )
        @test serial.result.wbgt_c == getproperty.(getproperty.(scalar, :result), :wbgt_c)
        @test threaded.result.wbgt_c == serial.result.wbgt_c
        @test threaded.input_status == serial.input_status
        @test threaded.globe.reason == serial.globe.reason
        @test threaded.natural_wet_bulb.reason == serial.natural_wet_bulb.reason

        value_outputs = (
            Vector{Union{Missing,Float64}}(undef, length(inputs.air)),
            Vector{Union{Missing,Float64}}(undef, length(inputs.air)),
            Vector{Union{Missing,Float64}}(undef, length(inputs.air)),
        )
        preallocated = _compat_liljegren_wbgt!(
            value_outputs...,
            inputs.air, inputs.dew, inputs.wind, inputs.radiation, inputs.time,
            inputs.longitude, inputs.latitude;
            pressure_hpa = inputs.pressure,
            direct_fraction = inputs.direct,
        )
        @test preallocated.wbgt_c == serial.result.wbgt_c
        @test preallocated.natural_wet_bulb_c == serial.result.natural_wet_bulb_c
        @test preallocated.globe_temperature_c == serial.result.globe_temperature_c

        tighter = _compat_liljegren_wbgt_batch(
            inputs.air, inputs.dew, inputs.wind, inputs.radiation, inputs.time,
            inputs.longitude, inputs.latitude;
            pressure_hpa = inputs.pressure,
            direct_fraction = inputs.direct,
            config = LiljegrenConfig(
                solver = SolverConfig(
                    root_tolerance_k = 1e-7,
                    residual_tolerance_k = 1e-5,
                ),
            ),
        )
        for index in eachindex(inputs.air)
            default_value = serial.result.wbgt_c[index]
            tighter_value = tighter.wbgt_c[index]
            if !ismissing(default_value) && !ismissing(tighter_value)
                @test abs(default_value - tighter_value) <= 5e-4
            end
        end

        permutation = reverse(eachindex(inputs.air))
        permuted = _compat_liljegren_wbgt_batch(
            inputs.air[permutation], inputs.dew[permutation],
            inputs.wind[permutation], inputs.radiation[permutation],
            inputs.time[permutation], inputs.longitude[permutation],
            inputs.latitude[permutation];
            pressure_hpa = inputs.pressure[permutation],
            direct_fraction = inputs.direct[permutation],
        )
        @test permuted.wbgt_c == reverse(serial.result.wbgt_c)
        @test permuted.natural_wet_bulb_c == reverse(serial.result.natural_wet_bulb_c)
        @test permuted.globe_temperature_c == reverse(serial.result.globe_temperature_c)

        for (index, diagnostic) in enumerate(scalar)
            @test diagnostic.input_status === InputAccepted
            _v3_assert_component_invariants(diagnostic.globe)
            _v3_assert_component_invariants(diagnostic.natural_wet_bulb)
            for value in (
                diagnostic.result.wbgt_c,
                diagnostic.result.natural_wet_bulb_c,
                diagnostic.result.globe_temperature_c,
            )
                @test ismissing(value) || isfinite(value)
            end
            if !ismissing(diagnostic.result.wbgt_c)
                @test diagnostic.result.wbgt_c ≈
                      0.7 * diagnostic.result.natural_wet_bulb_c +
                      0.2 * diagnostic.result.globe_temperature_c +
                      0.1 * inputs.air[index] atol = 2eps(Float64)
            end
        end
    end

    @testset "standalone recomputation" begin
        generator = joinpath(_V3_VALIDATION_ROOT, "generate_fixture_set_v3.jl")
        command = `$(Base.julia_cmd()) --startup-file=no --project=$(joinpath(_V3_VALIDATION_ROOT, "high_precision")) $generator --check`
        @test success(pipeline(command; stdout = devnull, stderr = stderr))
    end
end
