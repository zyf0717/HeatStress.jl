# Standalone 256-bit reference generator for scalar Liljegren fixtures.
# It intentionally does not import HeatStress or invoke package kernels.
using Dates
using TOML

const B = BigFloat
b(x::AbstractString) = parse(B, x)
b(x::Real) = B(x)
const σ = b("5.6696e-8")
const cp = b("1003.5")
const ma = b("28.97")
const mw = b("18.015")
const R = b("8314.34")
const πb = big(π)

sat(t) = b("6.108") * exp(b("17.27") * t / (t + b("237.3")))
ρair(t, p) = p * b("100") * ma / (R * t)

function μair(t)
    tr = t / b("97")
    Ω = b("1.16145") * tr^b("-0.14874") +
        b("0.52487") * exp(-b("0.77320") * tr) +
        b("2.16178") * exp(-b("2.43787") * tr)
    return b("2.6693e-6") * sqrt(ma * t) / (b("3.617")^2 * Ω)
end

kair(t) = b("5.75e-5") * (one(B) + b("0.00317") * (t - b("273.15")) -
          b("0.0000021") * (t - b("273.15"))^2) * b("418.4")

function diffusivity(t, p)
    tc = b("132.6") * b("647.1")
    pc = b("217.7") * b("37.36")
    return b("0.000364") * (t / sqrt(tc))^b("2.334") * pc^inv(b(3)) * tc^(b(5) / b(12)) *
           sqrt(inv(ma) + inv(mw)) / ((p / b("1013.25")) * b("10000"))
end

function mass_ratio(t, p, ρ, μ)
    pr = cp * μ / kair(t)
    sc = μ / (ρ * diffusivity(t, p))
    return mw / ma * (pr / sc)^b("0.56")
end

function hsphere(t, p, wind, d)
    ρ, μ, k = ρair(t, p), μair(t), kair(t)
    re, pr = ρ * wind * d / μ, cp * μ / k
    return (b("2") + b("0.6") * sqrt(re) * cbrt(pr)) * k / d
end

function hcylinder(t, wind, d, ρ, μ)
    k = kair(t)
    re, pr = ρ * wind * d / μ, cp * μ / k
    return b("0.281") * re^b("0.6") * pr^b("0.44") * k / d
end

latent(t) = b("1e6") * (b("1.748942") + b("0.01405870") * t -
            b("6.376351e-5") * t^2 + b("8.187135e-8") * t^3)

function solar_zenith(time, longitude_deg, latitude_deg)
    γ = b(2) * πb * B(dayofyear(time) - 1) / b("365")
    δ = b("0.006918") - b("0.399912") * cos(γ) + b("0.070257") * sin(γ) -
        b("0.006758") * cos(b(2) * γ) + b("0.000907") * sin(b(2) * γ) -
        b("0.002697") * cos(b(3) * γ) + b("0.00148") * sin(b(3) * γ)
    eot = (b("0.0000075") + b("0.001868") * cos(γ) - b("0.032077") * sin(γ) -
           b("0.014615") * cos(b(2) * γ) - b("0.040849") * sin(b(2) * γ)) * b("720") / πb
    minutes_since_midnight = B(60 * hour(time) + Dates.minute(time))
    hour_angle = πb * (minutes_since_midnight + eot + b("4") * longitude_deg - b("720")) / b("720")
    latitude = latitude_deg * πb / b("180")
    return acos(clamp(sin(latitude) * sin(δ) + cos(latitude) * cos(δ) * cos(hour_angle), -one(B), one(B)))
end

function solar_geometry(zenith)
    zenith >= πb / b(2) && return zero(B), zero(B)
    zenith > πb / b(2) - πb / b(180) && return zero(B), zero(B)
    return inv(b(2) * cos(zenith)), tan(zenith) / πb
end

function bisect(f, lower, upper)
    fl, fu = f(lower), f(upper)
    fl < zero(B) < fu || error("reference root is not bracketed: lower=$fl upper=$fu")
    for _ in 1:320
        mid = (lower + upper) / b(2)
        fm = f(mid)
        if fm < zero(B)
            lower, fl = mid, fm
        else
            upper, fu = mid, fm
        end
    end
    return (lower + upper) / b(2)
end

function reference_case(air_c, dew_c, wind, radiation, time, longitude, latitude; pressure=b("1010"), direct=b("0.7"))
    air, dew = air_c + b("273.15"), dew_c + b("273.15")
    zenith = solar_zenith(time, longitude, latitude)
    radiation = zenith >= πb / b(2) ? zero(B) : radiation
    globe_projection, wick_projection = solar_geometry(zenith)
    vapour = sat(dew_c)
    emissivity = b("0.575") * vapour^inv(b(7))
    effective_wind = max(wind, b("0.13"))

    globe_longwave = (emissivity + b("0.999")) * air^4 / b(2)
    globe_solar = radiation * (one(B) - b("0.05")) *
                  (one(B) - direct + direct * globe_projection + b("0.45")) /
                  (b(2) * b("0.95") * σ)
    globe_residual = function (tg)
        h = hsphere((tg + air) / b(2), pressure, effective_wind, b("0.0508"))
        radicand = globe_longwave - h * (tg - air) / (b("0.95") * σ) + globe_solar
        tg^4 - radicand
    end
    tg = bisect(globe_residual, air - b("200"), air + b("200"))

    ρ, μ = ρair(air, pressure), μair(air)
    ratio = mass_ratio(air, pressure, ρ, μ)
    wet_longwave = σ * b("0.95") * (emissivity + b("0.999")) * air^4 / b(2)
    diffuse = one(B) + b("0.007") / (b(4) * b("0.0254"))
    direct_geometry = wick_projection + b("0.007") / (b(4) * b("0.0254"))
    wet_solar = radiation * (one(B) - b("0.4")) *
                ((one(B) - direct) * diffuse + direct * direct_geometry + b("0.45"))
    wet_residual = function (tw)
        h = hcylinder(air, effective_wind, b("0.007"), ρ, μ)
        evaporation = latent(air) / cp * ratio * (sat(tw - b("273.15")) - vapour) / (pressure - sat(tw - b("273.15")))
        equilibrium = air - evaporation + (wet_longwave + wet_solar - σ * b("0.95") * tw^4) / h
        tw - equilibrium
    end
    tw = bisect(wet_residual, dew - one(B), air + b("3"))
    tg_c, tw_c = tg - b("273.15"), tw - b("273.15")
    return Dict("globe_temperature_c" => string(tg_c), "natural_wet_bulb_c" => string(tw_c),
                "wbgt_c" => string(b("0.7") * tw_c + b("0.2") * tg_c + b("0.1") * air_c))
end

function fixture(air_c, dew_c, wind, radiation, time, longitude, latitude)
    expected = reference_case(air_c, dew_c, wind, radiation, time, longitude, latitude)
    inputs = Dict(
        "air_temperature_c" => Float64(air_c),
        "dew_point_c" => Float64(dew_c),
        "wind_speed_m_s" => Float64(wind),
        "solar_radiation_w_m2" => Float64(radiation),
        "time" => string(time),
        "longitude_deg" => Float64(longitude),
        "latitude_deg" => Float64(latitude),
        "pressure_hpa" => 1010.0,
        "direct_fraction" => 0.7,
    )
    return merge(inputs, expected)
end

function main()
    setprecision(B, 256) do
        fixtures = Dict(
            "day" => fixture(b("30"), b("20"), b("1"), b("800"), DateTime(2024, 6, 21, 12), b("0"), b("0")),
            "night" => fixture(b("30"), b("20"), b("1"), b("800"), DateTime(2024, 6, 21), b("0"), b("0")),
            "saturated" => fixture(b("30"), b("30"), b("1"), b("800"), DateTime(2024, 6, 21, 12), b("0"), b("0")),
        )
        TOML.print(stdout, Dict("schema_version" => 1, "precision_bits" => 256, "fixtures" => fixtures))
    end
end

main()
