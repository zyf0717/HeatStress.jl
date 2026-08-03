using Test
using HeatStress

include("legacy_liljegren_api.jl")

@testset "HeatStress" begin
    @test isdefined(HeatStress, :HeatStress)
end

include("test_types.jl")
include("test_validation.jl")
include("test_solar_geometry.jl")
include("test_psychrometrics.jl")
include("test_wind_height.jl")
include("test_secondary_indices.jl")
include("test_physical_kernels.jl")
include("test_root_solver.jl")
include("test_liljegren_scalar.jl")
include("test_liljegren_batch.jl")
include("test_irradiance_inputs.jl")
include("test_scientific_validation.jl")
include("test_validation_v3.jl")

if get(ENV, "HEATSTRESS_QUALITY", "0") == "1"
    using Aqua
    using JET

    Aqua.test_all(HeatStress; ambiguities = false)
    JET.test_package(HeatStress; target_modules = (HeatStress,))
end
