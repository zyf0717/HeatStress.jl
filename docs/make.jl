using Documenter

pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))
using HeatStress

makedocs(
    modules = [HeatStress],
    sitename = "HeatStress.jl",
    pages = [
        "Home" => "index.md",
        "Units and input policies" => "units-and-policies.md",
        "Scientific provenance" => "provenance.md",
    ],
)
