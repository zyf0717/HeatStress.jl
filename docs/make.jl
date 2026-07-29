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
        "Secondary measures" => "secondary-measures.md",
        "Liljegren pipeline" => "liljegren.md",
        "Inputs and policies" => "inputs.md",
        "Numerical behaviour" => "numerical-behaviour.md",
        "Performance" => "performance.md",
        "Scientific provenance" => "provenance.md",
    ],
)
