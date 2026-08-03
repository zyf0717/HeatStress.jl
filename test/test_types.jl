@testset "public API types" begin
    @testset "completed Liljegren exports" begin
        exported_names = Set(names(HeatStress))
        expected_names = (
            :RadiationPartitionPolicy,
            :FixedDirectFraction,
            :LiljegrenClearnessFraction,
            :IrradianceDiagnostics,
            :IrradianceDiagnosticsBatch,
            :WindHeightPolicy,
            :NoWindHeightAdjustment,
            :LiljegrenStabilityPowerLaw,
            :WindTerrain,
            :Rural,
            :Urban,
            :PasquillStabilityClass,
            :WindHeightDiagnostics,
            :WindHeightDiagnosticsBatch,
            :wind_speed_at_height,
            :diagnose_wind_speed_at_height,
            :globe_temperature,
            :natural_wet_bulb_temperature,
            :liljegren_wbgt,
            :diagnose_liljegren,
            :liljegren_wbgt_batch,
            :liljegren_wbgt!,
            :diagnose_liljegren_batch,
        )
        @test all(name -> name in exported_names, expected_names)
    end

    @testset "policies" begin
        @test ClampDewPoint isa DewPointPolicy
        @test InputAccepted isa InputStatus
        @test NoFailure isa FailureReason
        @test FixedDirectFraction() isa RadiationPartitionPolicy
        @test FixedDirectFraction().value == 0.8
        @test LiljegrenClearnessFraction() isa RadiationPartitionPolicy
    end

    @testset "configuration validation and promotion" begin
        solver32 = @inferred SolverConfig(
            root_tolerance_k = 1f-6,
            residual_tolerance_k = 1f-4,
            maximum_iterations = 64,
        )
        @test solver32 isa SolverConfig{Float32}
        @test @inferred(LiljegrenConfig(solver = solver32)) isa LiljegrenConfig{Float32}
        @test LiljegrenConfig().dew_point_policy === ClampDewPoint
        @test LiljegrenConfig(dew_point_policy = SwapAirAndDewPoint).dew_point_policy ===
              SwapAirAndDewPoint
        @test LiljegrenConfig(dew_point_policy = RejectInvalidDewPoint).dew_point_policy ===
              RejectInvalidDewPoint

        @test_throws ArgumentError SolverConfig(root_tolerance_k = 0.0)
        @test_throws ArgumentError SolverConfig(residual_tolerance_k = Inf)
        @test_throws ArgumentError SolverConfig(residual_tolerance_k = 0.011)
        @test_throws ArgumentError SolverConfig(maximum_iterations = 0)
        @test_throws ArgumentError LiljegrenConfig(dew_point_tolerance_c = -1.0)
        @test_throws ArgumentError LiljegrenConfig(surface_albedo = 1.01)
        @test_throws ArgumentError LiljegrenConfig(globe_diameter_m = 0.0)
        @test_throws ArgumentError LiljegrenConfig(minimum_wind_speed_m_s = -0.01)
        @test_throws ArgumentError LiljegrenConfig(irradiance_closure_atol_w_m2 = -1.0)
        @test_throws ArgumentError LiljegrenConfig(irradiance_closure_kt_tolerance = -0.01)
        @test_throws ArgumentError FixedDirectFraction(-0.1)
        @test_throws ArgumentError FixedDirectFraction(1.1)
        @test_throws ArgumentError FixedDirectFraction([0.8, 1.1])
    end

    @testset "result containers" begin
        result32 = @inferred WBGTResult(25f0, 22f0, 30f0)
        @test result32 isa WBGTResult{Float32}
        @test @inferred(WBGTResult(missing, missing, missing)) isa WBGTResult{Float64}

        not_attempted = @inferred SolverDiagnostics{Float64}(
            false,
            NotAttempted,
            missing,
            missing,
            missing,
            0,
            0,
            missing,
            missing,
            missing,
            missing,
            missing,
            missing,
            1e-6,
            1e-4,
        )
        @test_throws ArgumentError SolverDiagnostics{Float64}(
            false,
            NotAttempted,
            missing,
            missing,
            missing,
            0,
            0,
            missing,
            missing,
            missing,
            missing,
            missing,
            missing,
            1e-6,
            0.011,
        )
        irradiance = IrradianceDiagnostics{Float64}(
            missing,
            missing,
            missing,
            missing,
            missing,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            missing,
            missing,
            false,
            :fixed,
        )
        diagnostic = @inferred DiagnosticWBGTResult{Float64}(
            WBGTResult(missing, missing, missing),
            MissingTime,
            false,
            false,
            false,
            false,
            false,
            WindHeightDiagnostics{Float64}(
                missing,
                missing,
                2.0,
                missing,
                missing,
                nothing,
                nothing,
                false,
                false,
                false,
            ),
            irradiance,
            not_attempted,
            not_attempted,
        )
        @test diagnostic isa DiagnosticWBGTResult{Float64}

        values = Union{Missing,Float64}[25.0, missing]
        batch = @inferred WBGTBatchResult(copy(values), copy(values), copy(values))
        @test batch isa WBGTBatchResult{Float64}
        @test_throws ArgumentError WBGTBatchResult(values, values, Union{Missing,Float64}[25.0])
    end
end
