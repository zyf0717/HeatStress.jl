module RCCReferenceGenerator

using Dates
using Printf

const HEADER = (
    "id", "time", "longitude_deg", "latitude_deg", "air_temperature_c",
    "relative_humidity_percent", "wind_speed_m_s", "ghi_w_m2",
    "pressure_hpa", "direct_fraction", "solar_zenith_deg",
    "psychrometric_wet_bulb_c", "rcc_nws_natural_wet_bulb_c",
    "rccnl_natural_wet_bulb_c", "dim228_globe_c", "dim167l_globe_c",
    "rcc_nws_wbgt_c", "rccd167l_wbgt_c", "atol_c", "rtol",
)

bf(value::AbstractString) = parse(BigFloat, value)
format_number(value::BigFloat) = @sprintf("%.17g", Float64(value))

const CASES = (
    (id="temperate_day", time=DateTime(2025, 7, 1, 12), lon="0", lat="0",
     air="32", rh="40", wind="2", ghi="800", pressure="900", direct="0.7"),
    (id="hot_dry_day", time=DateTime(2025, 6, 21, 19), lon="-105", lat="32",
     air="42", rh="12", wind="4.5", ghi="1050", pressure="850", direct="0.78"),
    (id="humid_day", time=DateTime(2025, 8, 8, 17), lon="-81", lat="28",
     air="34", rh="82", wind="1.2", ghi="720", pressure="1008", direct="0.55"),
    (id="low_sun", time=DateTime(2025, 3, 20, 7), lon="0", lat="0",
     air="24", rh="65", wind="0.4", ghi="80", pressure="1010", direct="0.12"),
    (id="night_zero_radiation", time=DateTime(2025, 7, 1, 0), lon="0", lat="0",
     air="27", rh="75", wind="1.5", ghi="0", pressure="1000", direct="0.7"),
    (id="saturated", time=DateTime(2025, 9, 1, 14), lon="10", lat="45",
     air="20", rh="100", wind="3", ghi="500", pressure="950", direct="0.5"),
    (id="near_calm", time=DateTime(2025, 5, 15, 12), lon="0", lat="15",
     air="30", rh="30", wind="0.05", ghi="900", pressure="1010", direct="0.75"),
    (id="cool_low_radiation", time=DateTime(2025, 11, 1, 10), lon="5", lat="50",
     air="8", rh="88", wind="7", ghi="120", pressure="1030", direct="0.2"),
)

function solar_zenith(time, longitude, latitude)
    day = dayofyear(time)
    gamma = bf("2") * big(π) * bf(string(day - 1)) / bf("365")
    declination = bf("0.006918") - bf("0.399912") * cos(gamma) +
        bf("0.070257") * sin(gamma) - bf("0.006758") * cos(bf("2") * gamma) +
        bf("0.000907") * sin(bf("2") * gamma) -
        bf("0.002697") * cos(bf("3") * gamma) +
        bf("0.00148") * sin(bf("3") * gamma)
    equation = bf("0.0000075") + bf("0.001868") * cos(gamma) -
        bf("0.032077") * sin(gamma) - bf("0.014615") * cos(bf("2") * gamma) -
        bf("0.040849") * sin(bf("2") * gamma)
    equation_minutes = equation * bf("720") / big(π)
    utc_minutes = bf(string(60hour(time) + minute(time))) +
                  bf(string(second(time))) / bf("60") +
                  bf(string(millisecond(time))) / bf("60000")
    hour_angle = big(π) * (
        utc_minutes + equation_minutes + bf("4") * longitude - bf("720")
    ) / bf("720")
    latitude_rad = latitude * big(π) / bf("180")
    cosine = sin(latitude_rad) * sin(declination) +
             cos(latitude_rad) * cos(declination) * cos(hour_angle)
    return acos(clamp(cosine, bf("-1"), bf("1"))) * bf("180") / big(π)
end

function psychrometric_wet_bulb(air, rh, pressure)
    air_k = air + bf("273.15")
    y = (air_k - bf("273.15")) / (air_k - bf("32.18"))
    vapour = rh / bf("100") * bf("1.004") * bf("6.1121") *
             exp(bf("17.502") * y)
    z = log(vapour / (bf("6.1121") * bf("1.004")))
    dew = bf("240.97") * z / (bf("17.502") - z)
    fp = bf("0.0006355") * pressure
    saturation(value) = bf("6.11") * bf("10")^(
        bf("7.5") * value / (value + bf("237.3"))
    )
    es = saturation(air)
    ed = saturation(dew)
    difference = air - dew
    wet = if iszero(difference)
        air
    else
        slope = (es - ed) / difference
        (air * fp + dew * slope) / (fp + slope)
    end
    for _ in 1:5
        wet_k = wet + bf("273.15")
        ew = saturation(wet)
        residual = fp * (air - wet) - (ew - ed)
        derivative = ew * (bf("0.0091") - bf("6106.4") / wet_k^2) - fp
        wet = wet_k - residual / derivative - bf("273.15")
    end
    return wet
end

function natural_wet_bulbs(air, rh, wind, ghi, pressure)
    wet = psychrometric_wet_bulb(air, rh, pressure)
    depression = air - wet
    nws = wet + bf("0.001651") * ghi - bf("0.09555") * wind +
          bf("0.13235") * depression + bf("0.20249")
    nonlinear = wet + (
        -bf("0.000003") * ghi^2 + bf("0.0046") * ghi +
        bf("0.135") * depression
    ) / wind^bf("0.15") - bf("0.0443")
    return wet, nws, nonlinear
end

function globe(air, rh, wind, ghi, zenith, direct, day_coefficient, liljegren_gain)
    sigma = bf("0.0000000567")
    vapour = rh / bf("100") * bf("1.004") * bf("6.1121") *
             exp(bf("17.502") * air / (air + bf("240.97")))
    emissivity = bf("0.575") * vapour^(inv(bf("7")))
    solar = if iszero(ghi)
        zero(BigFloat)
    else
        cosine = cos(zenith * big(π) / bf("180"))
        direct_gain = direct / (bf("4") * sigma * cosine)
        diffuse = one(BigFloat) - direct
        diffuse_gain = liljegren_gain ?
            (diffuse + bf("0.2")) / (bf("2") * sigma) :
            bf("1.2") * diffuse / sigma
        ghi * (direct_gain + diffuse_gain)
    end
    longwave = liljegren_gain ?
        (one(BigFloat) + emissivity) * air^4 / bf("2") : emissivity * air^4
    h = zenith < bf("87") ? day_coefficient : zero(BigFloat)
    wind_hr = max(wind, bf("1")) * bf("3600")
    c = h * wind_hr^bf("0.58") / (bf("0.95") * sigma)
    return (solar + longwave + c * air + bf("7680000")) /
           (c + bf("256000"))
end

function row(case)
    air, rh, wind, ghi, pressure, direct =
        bf.((case.air, case.rh, case.wind, case.ghi, case.pressure, case.direct))
    longitude, latitude = bf.((case.lon, case.lat))
    zenith = solar_zenith(case.time, longitude, latitude)
    wet, nws_wet, nonlinear_wet = natural_wet_bulbs(air, rh, wind, ghi, pressure)
    dim228 = globe(air, rh, wind, ghi, zenith, direct, bf("0.228"), false)
    dim167 = globe(air, rh, wind, ghi, zenith, direct, bf("0.167"), true)
    nws_wbgt = bf("0.1") * air + bf("0.2") * dim228 + bf("0.7") * nws_wet
    rccd_wbgt = bf("0.1") * air + bf("0.2") * dim167 + bf("0.7") * nonlinear_wet
    numbers = (
        longitude, latitude, air, rh, wind, ghi, pressure, direct, zenith, wet,
        nws_wet, nonlinear_wet, dim228, dim167, nws_wbgt, rccd_wbgt,
    )
    return join((
        case.id,
        string(case.time),
        format_number.(numbers)...,
        "2e-10",
        "2e-12",
    ), ',')
end

function generate(io::IO)
    setprecision(BigFloat, 256) do
        println(io, join(HEADER, ','))
        foreach(case -> println(io, row(case)), CASES)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if !isempty(ARGS) && only(ARGS) == "-"
        generate(stdout)
    else
        output = joinpath(@__DIR__, "fixtures", "rcc_wbgt.csv")
        open(generate, output, "w")
        println(output)
    end
end

end
