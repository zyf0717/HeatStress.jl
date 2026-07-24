using Test
using HeatStress

@testset "HeatStress" begin
    @test isdefined(HeatStress, :HeatStress)
end

if get(ENV, "HEATSTRESS_QUALITY", "0") == "1"
    using Aqua
    using JET

    Aqua.test_all(HeatStress; ambiguities = false)
    JET.test_package(HeatStress; target_defined_modules = true)
end
