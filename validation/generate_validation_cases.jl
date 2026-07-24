# Deterministically materialise the small v0.1 validation corpus.  The scalar
# values originate in the standalone 256-bit generator in test/fixtures; this
# script deliberately does not import HeatStress or call package kernels.
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const FIXTURES = joinpath(@__DIR__, "fixtures")

function main()
    references = TOML.parsefile(joinpath(ROOT, "test", "fixtures", "liljegren_scalar_reference.toml"))["fixtures"]
    open(joinpath(FIXTURES, "liljegren_reference.csv"), "w") do io
        println(io, "id,air_temperature_c,dew_point_c,wind_speed_m_s,solar_radiation_w_m2,time,longitude_deg,latitude_deg,pressure_hpa,direct_fraction,expected_globe_c,expected_natural_wet_bulb_c,expected_wbgt_c,authority,source_id,atol_c")
        for id in sort!(collect(keys(references)))
            row = references[id]
            println(io, join((id, row["air_temperature_c"], row["dew_point_c"], row["wind_speed_m_s"], row["solar_radiation_w_m2"], row["time"], row["longitude_deg"], row["latitude_deg"], row["pressure_hpa"], row["direct_fraction"], row["globe_temperature_c"], row["natural_wet_bulb_c"], row["wbgt_c"], "high_precision", "liljegren_2008", "1e-4"), ','))
        end
    end
    return nothing
end

abspath(PROGRAM_FILE) == @__FILE__ && main()
