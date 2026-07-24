using Documenter

pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))
using HeatStress

makedocs(
    modules = [HeatStress],
    sitename = "HeatStress.jl",
    pages = [
        "Home" => "index.md",
        "Scientific provenance" => "provenance.md",
    ],
)
