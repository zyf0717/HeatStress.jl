module SimpleIndexReferenceGenerator

const FIXTURE = joinpath(@__DIR__, "fixtures", "simple_indices.csv")
const HEADER = (
    "id", "formula", "air_temperature_c", "dew_point_c",
    "relative_humidity_percent", "natural_wet_bulb_c",
    "globe_temperature_c", "dry_bulb_temperature_c", "expected_value",
    "authority", "source_id", "atol", "rtol",
)

bf(value::AbstractString) = parse(BigFloat, value)

function wbgt_with_solar(wet, globe, dry)
    return bf("0.7") * wet + bf("0.2") * globe + bf("0.1") * dry
end

wbgt_without_solar(wet, globe) = bf("0.7") * wet + bf("0.3") * globe

celsius_to_fahrenheit(value) = bf("1.8") * value + bf("32")
fahrenheit_to_celsius(value) = (value - bf("32")) / bf("1.8")

function heat_index(temperature_c, humidity)
    temperature_f = celsius_to_fahrenheit(temperature_c)
    estimate = bf("0.5") * (
        temperature_f + bf("61") +
        bf("1.2") * (temperature_f - bf("68")) +
        bf("0.094") * humidity
    )
    estimate = bf("0.5") * (estimate + temperature_f)
    estimate < bf("80") && return fahrenheit_to_celsius(estimate)

    temperature_squared = temperature_f^2
    humidity_squared = humidity^2
    result = bf("-42.379") +
             bf("2.04901523") * temperature_f +
             bf("10.14333127") * humidity -
             bf("0.22475541") * temperature_f * humidity -
             bf("0.00683783") * temperature_squared -
             bf("0.05481717") * humidity_squared +
             bf("0.00122874") * temperature_squared * humidity +
             bf("0.00085282") * temperature_f * humidity_squared -
             bf("0.00000199") * temperature_squared * humidity_squared
    if humidity < bf("13") && bf("80") <= temperature_f <= bf("112")
        result -= (bf("13") - humidity) / bf("4") *
                  sqrt((bf("17") - abs(temperature_f - bf("95"))) / bf("17"))
    elseif humidity > bf("85") && bf("80") <= temperature_f <= bf("87")
        result += (humidity - bf("85")) / bf("10") *
                  (bf("87") - temperature_f) / bf("5")
    end
    return fahrenheit_to_celsius(result)
end

function stull_wet_bulb(temperature, humidity)
    return temperature * atan(bf("0.151977") * sqrt(humidity + bf("8.313659"))) +
           atan(temperature + humidity) -
           atan(humidity - bf("1.676331")) +
           bf("0.00391838") * humidity * sqrt(humidity) *
           atan(bf("0.023101") * humidity) -
           bf("4.686035")
end

function humidex_value(temperature, dew_point)
    dew_point_k = dew_point + bf("273.15")
    vapour_pressure = bf("6.11") * exp(
        bf("5417.7530") * (inv(bf("273.15")) - inv(dew_point_k)),
    )
    return temperature + bf("0.5555") * (vapour_pressure - bf("10"))
end

const CASES = (
    (
        id = "wbgt_solar_basic", formula = "wbgt_with_solar_load",
        air = nothing, dew = nothing, humidity = nothing,
        wet = "20", globe = "30", dry = "25",
        authority = "analytic", source = "osha_wbgt", atol = "1e-12",
    ),
    (
        id = "wbgt_solar_decimal", formula = "wbgt_with_solar_load",
        air = nothing, dew = nothing, humidity = nothing,
        wet = "28.2", globe = "36.4", dry = "31",
        authority = "analytic", source = "osha_wbgt", atol = "1e-12",
    ),
    (
        id = "wbgt_no_solar_basic", formula = "wbgt_without_solar_load",
        air = nothing, dew = nothing, humidity = nothing,
        wet = "20", globe = "30", dry = nothing,
        authority = "analytic", source = "osha_wbgt", atol = "1e-12",
    ),
    (
        id = "wbgt_no_solar_decimal", formula = "wbgt_without_solar_load",
        air = nothing, dew = nothing, humidity = nothing,
        wet = "28.2", globe = "36.4", dry = nothing,
        authority = "analytic", source = "osha_wbgt", atol = "1e-12",
    ),
    (
        id = "heat_index_simple", formula = "heat_index_nws",
        air = "20", dew = nothing, humidity = "50",
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "nws_heat_index", atol = "1e-10",
    ),
    (
        id = "heat_index_rothfusz", formula = "heat_index_nws",
        air = "32", dew = nothing, humidity = "70",
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "nws_heat_index", atol = "1e-10",
    ),
    (
        id = "heat_index_low_rh_adjustment", formula = "heat_index_nws",
        air = "40", dew = nothing, humidity = "10",
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "nws_heat_index", atol = "1e-10",
    ),
    (
        id = "heat_index_high_rh_adjustment", formula = "heat_index_nws",
        air = "30", dew = nothing, humidity = "90",
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "nws_heat_index", atol = "1e-10",
    ),
    (
        id = "stull_published_example", formula = "wet_bulb_temperature_stull",
        air = "20", dew = nothing, humidity = "50",
        wet = nothing, globe = nothing, dry = nothing,
        authority = "published_example", source = "stull_2011", atol = "1e-10",
    ),
    (
        id = "stull_warm_humid", formula = "wet_bulb_temperature_stull",
        air = "30", dew = nothing, humidity = "70",
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "stull_2011", atol = "1e-10",
    ),
    (
        id = "humidex_warm", formula = "humidex",
        air = "30", dew = "20", humidity = nothing,
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "eccc_humidex", atol = "1e-10",
    ),
    (
        id = "humidex_reporting_threshold_not_domain", formula = "humidex",
        air = "15", dew = "10", humidity = nothing,
        wet = nothing, globe = nothing, dry = nothing,
        authority = "high_precision", source = "eccc_humidex", atol = "1e-10",
    ),
)

input(value) = isnothing(value) ? "" : value

function expected(case)
    if case.formula == "wbgt_with_solar_load"
        return wbgt_with_solar(bf(case.wet), bf(case.globe), bf(case.dry))
    elseif case.formula == "wbgt_without_solar_load"
        return wbgt_without_solar(bf(case.wet), bf(case.globe))
    elseif case.formula == "heat_index_nws"
        return heat_index(bf(case.air), bf(case.humidity))
    elseif case.formula == "wet_bulb_temperature_stull"
        return stull_wet_bulb(bf(case.air), bf(case.humidity))
    elseif case.formula == "humidex"
        return humidex_value(bf(case.air), bf(case.dew))
    end
    error("unsupported formula $(case.formula)")
end

function simple_indices_csv()
    return setprecision(BigFloat, 256) do
        io = IOBuffer()
        println(io, join(HEADER, ','))
        for case in CASES
            values = (
                case.id, case.formula, input(case.air), input(case.dew),
                input(case.humidity), input(case.wet), input(case.globe),
                input(case.dry), repr(Float64(expected(case))), case.authority,
                case.source, case.atol, "1e-12",
            )
            println(io, join(values, ','))
        end
        return String(take!(io))
    end
end

function fixture_matches()
    committed = replace(read(FIXTURE, String), "\r\n" => "\n")
    return simple_indices_csv() == committed
end

function main(args::Vector{String} = ARGS)
    args == String[] || args == ["--check"] ||
        error("usage: generate_simple_indices.jl [--check]")
    if args == ["--check"]
        fixture_matches() || error("$FIXTURE differs from deterministic regeneration")
        return nothing
    end
    open(FIXTURE, "w") do io
        write(io, simple_indices_csv())
    end
    return nothing
end

end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && SimpleIndexReferenceGenerator.main()
