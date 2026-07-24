using Documenter

pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))
using HeatStress

makedocs(
    modules = [HeatStress],
    checkdocs = :exports,
    sitename = "HeatStress.jl",
    pages = [
        "Home" => "index.md",
        "Architecture" => "architecture.md",
        "Public API" => "api.md",
        "Liljegren pipeline" => "liljegren.md",
        "Units and input policies" => "units-and-policies.md",
        "Scientific provenance" => "provenance.md",
    ],
)
