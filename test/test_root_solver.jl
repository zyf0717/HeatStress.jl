using Test
using HeatStress

@testset "safeguarded root solver" begin
    config = SolverConfig(root_tolerance_k = 1e-6, residual_tolerance_k = 1e-4, maximum_iterations = 64)
    globe_policy = HeatStress._GlobeBracketExpansion()

    @testset "location and endpoint cases" begin
        linear = HeatStress._solve_bracketed(x -> x - 2.0, 0.0, 4.0, globe_policy, -10.0, 10.0, config)
        @test linear.converged
        @test linear.reason === NoFailure
        @test linear.candidate_k == 2.0
        @test linear.evaluations == 3
        @test linear.iterations == 1
        @test linear.final_lower_k == linear.final_upper_k == 2.0

        nonlinear = HeatStress._solve_bracketed(x -> x^2 - 2.0, 0.0, 2.0, globe_policy, -10.0, 10.0, config)
        repeated = HeatStress._solve_bracketed(x -> x^2 - 2.0, 0.0, 2.0, globe_policy, -10.0, 10.0, config)
        @test nonlinear.converged
        @test nonlinear.candidate_k ≈ sqrt(2) atol = config.root_tolerance_k
        @test nonlinear == repeated
        @test nonlinear.final_upper_k - nonlinear.final_lower_k <= config.root_tolerance_k
        @test nonlinear.lower_location_residual * nonlinear.upper_location_residual <= 0

        lower_endpoint = HeatStress._solve_bracketed(x -> x - 1.0, 1.0, 3.0, globe_policy, -10.0, 10.0, config)
        upper_endpoint = HeatStress._solve_bracketed(x -> x - 3.0, 1.0, 3.0, globe_policy, -10.0, 10.0, config)
        @test lower_endpoint.candidate_k == 1.0
        @test upper_endpoint.candidate_k == 3.0
        @test lower_endpoint.evaluations == upper_endpoint.evaluations == 2
        @test lower_endpoint.iterations == upper_endpoint.iterations == 0
    end

    @testset "bracket recovery and failures" begin
        expanded = HeatStress._solve_bracketed(x -> x - 20.0, 0.0, 2.0, globe_policy, -10.0, 30.0, config)
        @test expanded.converged
        @test expanded.initial_upper_k == 2.0
        @test expanded.final_upper_k >= 20.0

        lower_expanded = HeatStress._solve_bracketed(
            x -> x + 20.0,
            0.0,
            2.0,
            globe_policy,
            -30.0,
            30.0,
            config,
        )
        @test lower_expanded.converged
        @test lower_expanded.initial_lower_k == 0.0
        @test lower_expanded.final_lower_k <= -20.0

        wet_expanded = HeatStress._solve_bracketed(
            x -> x - 15.0,
            0.0,
            1.0,
            HeatStress._WetBulbBracketExpansion(),
            -20.0,
            20.0,
            config,
        )
        @test wet_expanded.converged
        @test wet_expanded.initial_lower_k == 0.0
        @test wet_expanded.final_upper_k >= 15.0

        unbracketed = HeatStress._solve_bracketed(x -> x^2 + 1.0, 0.0, 2.0, globe_policy, -5.0, 5.0, config)
        @test !unbracketed.converged
        @test unbracketed.reason === Unbracketed
        @test ismissing(unbracketed.candidate_k)

        nonfinite_endpoint = HeatStress._solve_bracketed(
            x -> x == 0.0 ? NaN : x - 1.0,
            0.0,
            2.0,
            globe_policy,
            -5.0,
            5.0,
            config,
        )
        @test nonfinite_endpoint.reason === NonFiniteResidual
        @test nonfinite_endpoint.evaluations == 2

        nonfinite_interior = HeatStress._solve_bracketed(
            x -> x == 1.0 ? NaN : x - 1.5,
            0.0,
            2.0,
            globe_policy,
            -5.0,
            5.0,
            config,
        )
        @test nonfinite_interior.reason === NonFiniteResidual
        @test nonfinite_interior.candidate_k == 1.0
        @test nonfinite_interior.evaluations == 3

        capped = HeatStress._solve_bracketed(
            x -> x - sqrt(2.0),
            0.0,
            2.0,
            globe_policy,
            -5.0,
            5.0,
            SolverConfig(root_tolerance_k = 1e-12, residual_tolerance_k = 1e-4, maximum_iterations = 1),
        )
        @test capped.reason === IterationLimit
        @test capped.candidate_k == 1.0
        @test capped.iterations == 1
        @test capped.evaluations == 3
    end

    @testset "independent residual validation" begin
        location = HeatStress._solve_bracketed(
            x -> x - 0.255,
            0.0,
            1.0,
            globe_policy,
            -1.0,
            2.0,
            SolverConfig(root_tolerance_k = 0.5, residual_tolerance_k = 0.001, maximum_iterations = 8),
        )
        strict = SolverConfig(root_tolerance_k = 0.5, residual_tolerance_k = 0.001, maximum_iterations = 8)
        relaxed = SolverConfig(root_tolerance_k = 0.5, residual_tolerance_k = 0.01, maximum_iterations = 8)
        rejected = HeatStress._solver_diagnostics(location, location.candidate_k - 0.255, strict)
        accepted = HeatStress._solver_diagnostics(location, location.candidate_k - 0.255, relaxed)
        @test location.converged
        @test rejected.reason === ResidualValidationFailed
        @test ismissing(rejected.value_c)
        @test !ismissing(rejected.candidate_c)
        @test accepted.reason === NoFailure
        @test accepted.value_c == accepted.candidate_c

        unbracketed = HeatStress._solve_bracketed(x -> x^2 + 1.0, 0.0, 2.0, globe_policy, -5.0, 5.0, strict)
        @test HeatStress._solver_diagnostics(unbracketed, missing, relaxed).reason === Unbracketed
    end

    @testset "component adapters and floating-point types" begin
        globe = _globe_balance_fixture()
        globe_diagnostic = HeatStress._solve_globe_balance(globe, config)
        @test globe_diagnostic.converged
        @test globe_diagnostic.reason === NoFailure
        @test globe_diagnostic.value_c ≈ 47.74173511564036 atol = 2e-6
        @test abs(globe_diagnostic.validation_residual_k) <= config.residual_tolerance_k
        globe_location = HeatStress._solve_bracketed(
            temperature_k -> HeatStress._globe_energy_residual_k4(temperature_k, globe),
            globe.air_temperature_k - 2.0,
            globe.air_temperature_k + 10.0,
            HeatStress._GlobeBracketExpansion(),
            globe.air_temperature_k - 200.0,
            globe.air_temperature_k + 200.0,
            config,
        )
        @test globe_diagnostic.evaluations == globe_location.evaluations + 1

        wet_bulb = _wet_bulb_balance_fixture()
        wet_bulb_diagnostic = HeatStress._solve_natural_wet_bulb_balance(wet_bulb, 294.0, config)
        @test wet_bulb_diagnostic.converged
        @test wet_bulb_diagnostic.reason === NoFailure
        @test abs(wet_bulb_diagnostic.validation_residual_k) <= config.residual_tolerance_k
        wet_bulb_location = HeatStress._solve_bracketed(
            temperature_k -> HeatStress._natural_wet_bulb_residual(temperature_k, wet_bulb),
            293.0,
            304.15,
            HeatStress._WetBulbBracketExpansion(),
            203.15,
            403.15,
            config,
        )
        @test wet_bulb_diagnostic.evaluations == wet_bulb_location.evaluations + 1

        unbracketed_globe = HeatStress.GlobeBalance(303.15, 1013.25, 1.0, 0.0, 1e14, 0.0508, 0.95)
        @test HeatStress._solve_globe_balance(unbracketed_globe, config).reason === Unbracketed

        config32 = SolverConfig(root_tolerance_k = 1f-6, residual_tolerance_k = 1f-4, maximum_iterations = 64)
        linear32 = @inferred HeatStress._solve_bracketed(
            x -> x - 2f0,
            0f0,
            4f0,
            globe_policy,
            -10f0,
            10f0,
            config32,
        )
        @test linear32 isa HeatStress._BracketedSolveResult{Float32}
        @test linear32.candidate_k == 2f0
        @test @inferred(HeatStress._solve_globe_balance(_globe_balance_fixture(Float32), config32)) isa SolverDiagnostics{Float32}
    end
end
