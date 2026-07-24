# Deterministically materialise only the high-precision Liljegren reference
# fixture. The other v0.1 fixture families are independently curated source or
# invariant records and are intentionally not rewritten by this script.
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const FIXTURES = joinpath(@__DIR__, "fixtures")
const REFERENCE_IDS = ("day", "night", "subminute", "saturated")

function _reference_csv()
    references = TOML.parsefile(joinpath(ROOT, "test", "fixtures", "liljegren_scalar_reference.toml"))["fixtures"]
    io = IOBuffer()
    println(io, "id,air_temperature_c,dew_point_c,wind_speed_m_s,solar_radiation_w_m2,time,longitude_deg,latitude_deg,pressure_hpa,direct_fraction,expected_globe_c,expected_natural_wet_bulb_c,expected_wbgt_c,authority,source_id,atol_c")
    for id in REFERENCE_IDS
        haskey(references, id) || error("missing high-precision reference fixture: $id")
        row = references[id]
        println(io, join((id, row["air_temperature_c"], row["dew_point_c"], row["wind_speed_m_s"], row["solar_radiation_w_m2"], row["time"], row["longitude_deg"], row["latitude_deg"], row["pressure_hpa"], row["direct_fraction"], row["globe_temperature_c"], row["natural_wet_bulb_c"], row["wbgt_c"], "high_precision", "liljegren_2008", "1e-4"), ','))
    end
    return String(take!(io))
end

function main(args::Vector{String} = ARGS)
    args == String[] || args == ["--check"] || error("usage: generate_validation_cases.jl [--check]")
    generated = _reference_csv()
    destination = joinpath(FIXTURES, "liljegren_reference.csv")
    if args == ["--check"]
        generated == read(destination, String) || error("$destination differs from deterministic high-precision regeneration")
        return nothing
    end
    open(destination, "w") do io
        write(io, generated)
    end
    return nothing
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
