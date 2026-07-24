# Run the independent 256-bit reference generator without loading HeatStress.
setprecision(BigFloat, 256)
include(joinpath(@__DIR__, "..", "..", "test", "fixtures", "generate_liljegren_scalar_references.jl"))
