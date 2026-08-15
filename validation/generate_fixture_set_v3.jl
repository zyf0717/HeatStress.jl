# Standalone fixture-set-v3 generator. This file deliberately does not import
# HeatStress or include any package source.
module FixtureSetV3Generator

using Dates
using SHA

const VALIDATION_ROOT = @__DIR__
const REPOSITORY_ROOT = normpath(joinpath(VALIDATION_ROOT, ".."))
const CASE_PATH = joinpath(VALIDATION_ROOT, "cases", "liljegren-v3.toml")
const FIXTURE_ROOT = joinpath(VALIDATION_ROOT, "fixtures", "v3")
const METADATA_PATH = joinpath(VALIDATION_ROOT, "metadata", "fixture-set-v3.toml")
const PRECISION_BITS = 256
const REFERENCE_ROWS = 64

const AIR_LEVELS = ("-30", "0", "25", "50")
const WIND_LEVELS = ("0", "0.13", "1", "10")
const RADIATION_LEVELS = ("0", "200", "800", "1200")
const PRESSURE_LEVELS = ("700", "850", "1010", "1100")
const DIRECT_LEVELS = ("0", "0.33", "0.67", "1")
const GEOMETRIES = (
    (name = "equatorial_noon", time = DateTime(2024, 3, 20, 12), longitude = "0", latitude = "0"),
    (name = "equatorial_night", time = DateTime(2024, 3, 20, 0), longitude = "0", latitude = "0"),
    (name = "midlatitude_low_sun", time = DateTime(2024, 12, 21, 15), longitude = "0", latitude = "45"),
    (name = "highlatitude_summer", time = DateTime(2024, 6, 21, 18), longitude = "-21.9426", latitude = "64.1466"),
)

const CaseIndex = NTuple{7,Int}

function combinations(count::Int, width::Int)
    result = Vector{Vector{Int}}()
    function visit(prefix::Vector{Int}, start::Int)
        if length(prefix) == width
            push!(result, copy(prefix))
            return
        end
        for value in start:(count - (width - length(prefix)) + 1)
            push!(prefix, value)
            visit(prefix, value + 1)
            pop!(prefix)
        end
    end
    visit(Int[], 1)
    return result
end

function candidate_rows()
    rows = CaseIndex[]
    for air in 0:3, dew in 0:3, wind in 0:3, radiation in 0:3,
            pressure in 0:3, direct in 0:3, geometry in 0:3
        push!(rows, (air, dew, wind, radiation, pressure, direct, geometry))
    end
    return rows
end

function selected_cases()
    candidates = candidate_rows()
    pair_columns = combinations(7, 2)
    triple_columns = combinations(7, 3)
    uncovered_pairs = Set(
        (Tuple(columns), levels)
        for columns in pair_columns
        for levels in Iterators.product((0:3 for _ in columns)...)
    )
    selected = CaseIndex[]
    selected_set = Set{CaseIndex}()

    while !isempty(uncovered_pairs)
        best = first(candidates)
        best_score = -1
        for case in candidates
            case in selected_set && continue
            score = count(
                ((Tuple(columns), Tuple(case[column] for column in columns)) in uncovered_pairs)
                for columns in pair_columns
            )
            if score > best_score
                best = case
                best_score = score
            end
        end
        push!(selected, best)
        push!(selected_set, best)
        for columns in pair_columns
            delete!(
                uncovered_pairs,
                (Tuple(columns), Tuple(best[column] for column in columns)),
            )
        end
    end

    covered_triples = Set{Tuple}()
    for case in selected, columns in triple_columns
        push!(covered_triples, (Tuple(columns), Tuple(case[column] for column in columns)))
    end
    while length(selected) < REFERENCE_ROWS
        best = first(candidates)
        best_score = -1
        for case in candidates
            case in selected_set && continue
            score = count(
                !((Tuple(columns), Tuple(case[column] for column in columns)) in covered_triples)
                for columns in triple_columns
            )
            if score > best_score
                best = case
                best_score = score
            end
        end
        push!(selected, best)
        push!(selected_set, best)
        for columns in triple_columns
            push!(covered_triples, (Tuple(columns), Tuple(best[column] for column in columns)))
        end
    end
    return selected
end

bf(value::AbstractString) = parse(BigFloat, value)
bf(value::Integer) = BigFloat(value)

function dew_point_value(air::BigFloat, level::Int)
    level == 0 && return air
    level == 1 && return air - bf("2")
    level == 2 && return air - bf("10")
    return bf("-40")
end

function case_inputs(index::Int, factors::CaseIndex)
    air_index, dew_index, wind_index, radiation_index, pressure_index,
        direct_index, geometry_index = factors
    air = bf(AIR_LEVELS[air_index + 1])
    geometry = GEOMETRIES[geometry_index + 1]
    return (
        id = "liljegren_v3_" * lpad(string(index), 3, '0'),
        factors = factors,
        air = air,
        dew = dew_point_value(air, dew_index),
        wind = bf(WIND_LEVELS[wind_index + 1]),
        radiation = bf(RADIATION_LEVELS[radiation_index + 1]),
        time = geometry.time,
        longitude = bf(geometry.longitude),
        latitude = bf(geometry.latitude),
        pressure = bf(PRESSURE_LEVELS[pressure_index + 1]),
        direct = bf(DIRECT_LEVELS[direct_index + 1]),
        geometry_name = geometry.name,
    )
end

function case_definitions(cases)
    io = IOBuffer()
    println(io, "schema_version = 1")
    println(io, "selection = \"deterministic greedy pairwise then three-way coverage\"")
    println(io, "rows = $(length(cases))")
    for (index, factors) in enumerate(cases)
        row = case_inputs(index, factors)
        println(io)
        println(io, "[[cases]]")
        println(io, "id = \"$(row.id)\"")
        println(io, "factor_indices = [$(join(factors, ", "))]")
        println(io, "geometry = \"$(row.geometry_name)\"")
        println(io, "air_temperature_c = \"$(row.air)\"")
        println(io, "dew_point_c = \"$(row.dew)\"")
        println(io, "wind_speed_m_s = \"$(row.wind)\"")
        println(io, "solar_radiation_w_m2 = \"$(row.radiation)\"")
        println(io, "time = \"$(row.time)\"")
        println(io, "longitude_deg = \"$(row.longitude)\"")
        println(io, "latitude_deg = \"$(row.latitude)\"")
        println(io, "pressure_hpa = \"$(row.pressure)\"")
        println(io, "direct_fraction = \"$(row.direct)\"")
    end
    return String(take!(io))
end

struct RootReference
    accepted::Bool
    reason::String
    root::Union{Nothing,BigFloat}
    residual::Union{Nothing,BigFloat}
    lower::BigFloat
    upper::BigFloat
end

function sign_change(left::BigFloat, right::BigFloat)
    return (left < 0 < right) || (right < 0 < left)
end

function finish_bisection(
    residual,
    lower::BigFloat,
    upper::BigFloat;
    validation_residual = residual,
)
    lower_residual = residual(lower)
    upper_residual = residual(upper)
    for _ in 1:512
        upper - lower <= bf("1e-30") && break
        midpoint = (lower + upper) / 2
        midpoint_residual = residual(midpoint)
        if iszero(midpoint_residual)
            lower = upper = midpoint
            break
        elseif sign_change(lower_residual, midpoint_residual)
            upper = midpoint
            upper_residual = midpoint_residual
        else
            lower = midpoint
            lower_residual = midpoint_residual
        end
    end
    root = (lower + upper) / 2
    validation_value = validation_residual(root)
    return RootReference(
        isfinite(validation_value),
        isfinite(validation_value) ? "NoFailure" : "NonFiniteResidual",
        root,
        validation_value,
        lower,
        upper,
    )
end

function globe_root(residual, validation_residual, air_k::BigFloat)
    initial_lower = air_k - 2
    initial_upper = air_k + 10
    minimum = air_k - 200
    maximum = air_k + 200
    lower = initial_lower
    upper = initial_upper
    lower_residual = residual(lower)
    upper_residual = residual(upper)
    if !isfinite(lower_residual) || !isfinite(upper_residual)
        return RootReference(false, "NonFiniteResidual", nothing, nothing, lower, upper)
    end
    while !sign_change(lower_residual, upper_residual)
        if lower_residual > 0 && upper_residual > 0
            next_lower = max(minimum, lower - (upper - lower))
            next_lower == lower &&
                return RootReference(false, "Unbracketed", nothing, nothing, lower, upper)
            lower = next_lower
            lower_residual = residual(lower)
        elseif lower_residual < 0 && upper_residual < 0
            next_upper = min(maximum, upper + (upper - lower))
            next_upper == upper &&
                return RootReference(false, "Unbracketed", nothing, nothing, lower, upper)
            upper = next_upper
            upper_residual = residual(upper)
        else
            break
        end
        (!isfinite(lower_residual) || !isfinite(upper_residual)) &&
            return RootReference(false, "NonFiniteResidual", nothing, nothing, lower, upper)
    end
    sign_change(lower_residual, upper_residual) ||
        return RootReference(false, "Unbracketed", nothing, nothing, lower, upper)
    return finish_bisection(
        residual,
        lower,
        upper;
        validation_residual,
    )
end

function wet_root(residual, air_k::BigFloat, dew_k::BigFloat)
    minimum = bf("233.15")
    maximum = bf("323.15")
    lower = max(dew_k - 1, minimum)
    upper = max(lower, min(maximum, air_k + 1))
    lower_residual = residual(lower)
    upper_residual = residual(upper)
    if !isfinite(lower_residual) || !isfinite(upper_residual)
        return RootReference(false, "NonFiniteResidual", nothing, nothing, lower, upper)
    end
    while !sign_change(lower_residual, upper_residual)
        next_lower = max(minimum, lower - min(BigFloat(10), lower - minimum))
        if next_lower != lower
            lower = next_lower
            lower_residual = residual(lower)
            !isfinite(lower_residual) &&
                return RootReference(false, "NonFiniteResidual", nothing, nothing, lower, upper)
            sign_change(lower_residual, upper_residual) && break
        end
        next_upper = min(maximum, upper + min(BigFloat(10), maximum - upper))
        next_upper == upper &&
            return RootReference(false, "Unbracketed", nothing, nothing, lower, upper)
        upper = next_upper
        upper_residual = residual(upper)
        !isfinite(upper_residual) &&
            return RootReference(false, "NonFiniteResidual", nothing, nothing, lower, upper)
    end
    return finish_bisection(residual, lower, upper)
end

function solar_zenith(time::DateTime, longitude_deg::BigFloat, latitude_deg::BigFloat)
    pi_value = BigFloat(pi)
    gamma = 2 * pi_value * BigFloat(dayofyear(time) - 1) / 365
    declination = bf("0.006918") - bf("0.399912") * cos(gamma) +
                  bf("0.070257") * sin(gamma) - bf("0.006758") * cos(2gamma) +
                  bf("0.000907") * sin(2gamma) - bf("0.002697") * cos(3gamma) +
                  bf("0.00148") * sin(3gamma)
    equation_of_time = (
        bf("0.0000075") + bf("0.001868") * cos(gamma) -
        bf("0.032077") * sin(gamma) - bf("0.014615") * cos(2gamma) -
        bf("0.040849") * sin(2gamma)
    ) * 720 / pi_value
    utc_minute = BigFloat(60 * hour(time) + minute(time)) +
                 BigFloat(second(time)) / 60 + BigFloat(millisecond(time)) / 60_000
    hour_angle = pi_value *
                 (utc_minute + equation_of_time + 4longitude_deg - 720) / 720
    latitude = latitude_deg * pi_value / 180
    cosine = sin(latitude) * sin(declination) +
             cos(latitude) * cos(declination) * cos(hour_angle)
    return acos(clamp(cosine, -one(BigFloat), one(BigFloat)))
end

function reference_case(row)
    sigma = bf("5.6696e-8")
    heat_capacity = bf("1003.5")
    molar_air = bf("28.97")
    molar_water = bf("18.015")
    gas_constant = bf("8314.34")
    air_k = row.air + bf("273.15")
    dew_k = row.dew + bf("273.15")
    zenith = solar_zenith(row.time, row.longitude, row.latitude)
    pi_value = BigFloat(pi)
    radiation = zenith >= pi_value / 2 ? zero(BigFloat) : row.radiation
    direct_projection, wick_projection = if zenith >= pi_value / 2 ||
                                            zenith >= pi_value / 2 - pi_value / 360
        (zero(BigFloat), zero(BigFloat))
    else
        (inv(2cos(zenith)), tan(zenith) / pi_value)
    end
    function buck_saturation(t, pressure)
        -bf("40") <= t <= bf("50") || return BigFloat(NaN)
        enhancement = bf("1.0007") + bf("3.46e-6") * pressure
        if t < 0
            return bf("6.1121") * enhancement *
                   exp(bf("17.966") * t / (bf("247.15") + t))
        end
        return bf("6.1121") * enhancement *
               exp(bf("17.502") * t / (bf("240.97") + t))
    end
    density(t, pressure) = pressure * 100 * molar_air / (gas_constant * t)
    function viscosity(t)
        reduced = t / 97
        collision = bf("1.16145") * reduced^bf("-0.14874") +
                    bf("0.52487") * exp(-bf("0.77320") * reduced) +
                    bf("2.16178") * exp(-bf("2.43787") * reduced)
        return bf("2.6693e-6") * sqrt(molar_air * t) / (bf("3.617")^2 * collision)
    end
    conductivity(t) = bf("5.75e-5") *
                      (1 + bf("0.00317") * (t - bf("273.15")) -
                       bf("0.0000021") * (t - bf("273.15"))^2) * bf("418.4")
    function diffusivity(t, pressure)
        critical_temperature = bf("132.6") * bf("647.1")
        critical_pressure = bf("217.7") * bf("37.36")
        return bf("0.000364") * (t / sqrt(critical_temperature))^bf("2.334") *
               critical_pressure^(inv(BigFloat(3))) *
               critical_temperature^(BigFloat(5) / 12) *
               sqrt(inv(molar_air) + inv(molar_water)) /
               ((pressure / bf("1013.25")) * 10_000)
    end
    function sphere_convection(t, pressure, wind, diameter)
        rho = density(t, pressure)
        mu = viscosity(t)
        k = conductivity(t)
        reynolds = rho * wind * diameter / mu
        prandtl = heat_capacity * mu / k
        return (2 + bf("0.6") * sqrt(reynolds) * cbrt(prandtl)) * k / diameter
    end
    function cylinder_convection(t, wind, diameter, rho, mu)
        k = conductivity(t)
        reynolds = rho * wind * diameter / mu
        prandtl = heat_capacity * mu / k
        return bf("0.281") * reynolds^bf("0.6") * prandtl^bf("0.44") * k / diameter
    end
    latent(t) = 1_000_000 * (
        bf("1.748942") + bf("0.01405870") * t -
        bf("6.376351e-5") * t^2 + bf("8.187135e-8") * t^3
    )

    vapour = buck_saturation(row.dew, row.pressure)
    emissivity = bf("0.575") * vapour^(inv(BigFloat(7)))
    effective_wind = max(row.wind, bf("0.13"))
    globe_longwave = (emissivity + 1) * air_k^4 / 2
    globe_solar = radiation * (1 - bf("0.05")) *
                  (1 - row.direct + row.direct * direct_projection + bf("0.45")) /
                  (2 * bf("0.95") * sigma)
    globe_residual = function (candidate)
        convection = sphere_convection(
            (candidate + air_k) / 2,
            row.pressure,
            effective_wind,
            bf("0.0508"),
        )
        radicand = globe_longwave -
                   convection * (candidate - air_k) / (bf("0.95") * sigma) +
                   globe_solar
        return candidate^4 - radicand
    end
    globe_validation_residual = function (candidate)
        convection = sphere_convection(
            (candidate + air_k) / 2,
            row.pressure,
            effective_wind,
            bf("0.0508"),
        )
        radicand = globe_longwave -
                   convection * (candidate - air_k) / (bf("0.95") * sigma) +
                   globe_solar
        return candidate - radicand^(inv(BigFloat(4)))
    end
    globe = globe_root(globe_residual, globe_validation_residual, air_k)

    wet_longwave = sigma * bf("0.95") * (emissivity + 1) * air_k^4 / 2
    diffuse_geometry = 1 + bf("0.007") / (4 * bf("0.0254"))
    direct_geometry = wick_projection + bf("0.007") / (4 * bf("0.0254"))
    wet_solar = radiation * (1 - bf("0.4")) *
                ((1 - row.direct) * diffuse_geometry +
                 row.direct * direct_geometry + bf("0.45"))
    wet_residual = function (candidate)
        film = (candidate + air_k) / 2
        rho = density(film, row.pressure)
        mu = viscosity(film)
        prandtl = heat_capacity * mu / conductivity(film)
        schmidt = mu / (rho * diffusivity(film, row.pressure))
        transfer_ratio = molar_water / molar_air * (prandtl / schmidt)^bf("0.56")
        convection = cylinder_convection(
            film,
            effective_wind,
            bf("0.007"),
            rho,
            mu,
        )
        candidate_c = candidate - bf("273.15")
        saturated = buck_saturation(candidate_c, row.pressure)
        evaporation = latent(film) / heat_capacity * transfer_ratio *
                      (saturated - vapour) / (row.pressure - saturated)
        equilibrium = air_k - evaporation +
                      (wet_longwave + wet_solar -
                       sigma * bf("0.95") * candidate^4) / convection
        return candidate - equilibrium
    end
    wet = wet_root(wet_residual, air_k, dew_k)
    wbgt = if globe.accepted && wet.accepted
        bf("0.7") * (wet.root - bf("273.15")) +
        bf("0.2") * (globe.root - bf("273.15")) + bf("0.1") * row.air
    else
        nothing
    end
    return (globe = globe, wet = wet, wbgt = wbgt)
end

csv_value(::Nothing) = ""
csv_value(value::BigFloat) = string(value)
csv_value(value) = string(value)

function reference_csv(cases)
    io = IOBuffer()
    println(
        io,
        join(
            (
                "id", "air_factor", "dew_factor", "wind_factor", "radiation_factor",
                "pressure_factor", "direct_factor", "geometry_factor",
                "air_temperature_c", "dew_point_c", "wind_speed_m_s",
                "solar_radiation_w_m2", "time", "longitude_deg", "latitude_deg",
                "pressure_hpa", "direct_fraction", "expected_input_status",
                "expected_globe_reason", "expected_wet_bulb_reason",
                "expected_globe_c", "expected_natural_wet_bulb_c", "expected_wbgt_c",
                "expected_globe_residual", "expected_wet_bulb_residual",
                "expected_globe_lower_k", "expected_globe_upper_k",
                "expected_wet_lower_k", "expected_wet_upper_k",
                "authority", "source_id", "atol_c", "rtol",
            ),
            ',',
        ),
    )
    for (index, factors) in enumerate(cases)
        row = case_inputs(index, factors)
        expected = reference_case(row)
        globe_c = expected.globe.accepted ? expected.globe.root - bf("273.15") : nothing
        wet_c = expected.wet.accepted ? expected.wet.root - bf("273.15") : nothing
        values = (
            row.id, factors..., row.air, row.dew, row.wind, row.radiation, row.time,
            row.longitude, row.latitude, row.pressure, row.direct, "InputAccepted",
            expected.globe.reason, expected.wet.reason, csv_value(globe_c),
            csv_value(wet_c), csv_value(expected.wbgt), csv_value(expected.globe.residual),
            csv_value(expected.wet.residual), expected.globe.lower, expected.globe.upper,
            expected.wet.lower, expected.wet.upper, "high_precision", "liljegren_2008",
            "1e-4", "1e-8",
        )
        println(io, join(values, ','))
    end
    return String(take!(io))
end

function component_csv(reference::String)
    lines = split(chomp(reference), '\n')
    header = split(first(lines), ',')
    wanted = (
        "id", "expected_globe_reason", "expected_wet_bulb_reason",
        "expected_globe_c", "expected_natural_wet_bulb_c",
        "expected_globe_residual", "expected_wet_bulb_residual",
        "expected_globe_lower_k", "expected_globe_upper_k",
        "expected_wet_lower_k", "expected_wet_upper_k", "authority", "source_id",
        "atol_c", "rtol",
    )
    positions = [findfirst(==(name), header) for name in wanted]
    io = IOBuffer()
    println(io, join(wanted, ','))
    for line in Iterators.take(Iterators.drop(lines, 1), 16)
        fields = split(line, ','; keepempty = true)
        println(io, join((fields[position] for position in positions), ','))
    end
    return String(take!(io))
end

function psychrometrics_csv()
    cases = (
        ("cold_dry", "-40", "0"), ("cold_saturated", "-40", "100"),
        ("subfreezing_dry", "-30", "5"), ("subfreezing_humid", "-30", "85"),
        ("freezing_zero", "0", "0"), ("freezing_saturated", "0", "100"),
        ("temperate_dry", "20", "5"), ("temperate_mid", "20", "50"),
        ("temperate_saturated", "20", "100"), ("warm_mid", "30", "50"),
        ("warm_humid", "30", "85"), ("warm_saturated", "30", "100"),
        ("hot_dry", "50", "0"), ("hot_low", "50", "5"),
        ("hot_mid", "50", "50"), ("hot_saturated", "50", "100"),
    )
    saturation(t) = bf("6.108") * exp(bf("17.27") * t / (t + bf("237.3")))
    io = IOBuffer()
    println(io, "id,air_temperature_c,relative_humidity_percent,expected_saturation_hpa,expected_actual_hpa,authority,source_id,atol,rtol")
    for (id, temperature_text, humidity_text) in cases
        temperature = bf(temperature_text)
        humidity = bf(humidity_text)
        saturation_value = saturation(temperature)
        actual = humidity / 100 * saturation_value
        println(io, join((id, temperature, humidity, saturation_value, actual,
            "analytic", "fao56", "1e-12", "1e-12"), ','))
    end
    return String(take!(io))
end

function physical_csv()
    temperatures = ("233.15", "270", "300", "323.15")
    pressures = ("700", "1010", "1100")
    winds = ("0.13", "1", "10")
    vapour_pressures = ("1", "20", "60")
    molar_air = bf("28.97")
    molar_water = bf("18.015")
    gas_constant = bf("8314.34")
    heat_capacity = bf("1003.5")
    function viscosity(t)
        reduced = t / 97
        collision = bf("1.16145") * reduced^bf("-0.14874") +
                    bf("0.52487") * exp(-bf("0.77320") * reduced) +
                    bf("2.16178") * exp(-bf("2.43787") * reduced)
        return bf("2.6693e-6") * sqrt(molar_air * t) / (bf("3.617")^2 * collision)
    end
    conductivity(t) = bf("5.75e-5") *
                      (1 + bf("0.00317") * (t - bf("273.15")) -
                       bf("0.0000021") * (t - bf("273.15"))^2) * bf("418.4")
    function diffusivity(t, pressure)
        critical_temperature = bf("132.6") * bf("647.1")
        critical_pressure = bf("217.7") * bf("37.36")
        return bf("0.000364") * (t / sqrt(critical_temperature))^bf("2.334") *
               critical_pressure^(inv(BigFloat(3))) *
               critical_temperature^(BigFloat(5) / 12) *
               sqrt(inv(molar_air) + inv(molar_water)) /
               ((pressure / bf("1013.25")) * 10_000)
    end
    density(t, pressure) = pressure * 100 * molar_air / (gas_constant * t)
    emissivity(vapour) = bf("0.575") * vapour^(inv(BigFloat(7)))
    function sphere_convection(t, pressure, wind)
        rho = density(t, pressure)
        mu = viscosity(t)
        k = conductivity(t)
        reynolds = rho * wind * bf("0.0508") / mu
        prandtl = heat_capacity * mu / k
        return (2 + bf("0.6") * sqrt(reynolds) * cbrt(prandtl)) *
               k / bf("0.0508")
    end
    function cylinder_convection(t, pressure, wind)
        rho = density(t, pressure)
        mu = viscosity(t)
        k = conductivity(t)
        reynolds = rho * wind * bf("0.007") / mu
        prandtl = heat_capacity * mu / k
        return bf("0.281") * reynolds^bf("0.6") * prandtl^bf("0.44") *
               k / bf("0.007")
    end
    latent(t) = 1_000_000 * (
        bf("1.748942") + bf("0.01405870") * t -
        bf("6.376351e-5") * t^2 + bf("8.187135e-8") * t^3
    )
    io = IOBuffer()
    println(io, "id,temperature_k,pressure_hpa,wind_speed_m_s,vapour_pressure_hpa,expected_density_kg_m3,expected_viscosity_pa_s,expected_conductivity_w_mk,expected_diffusivity_m2_s,expected_emissivity,expected_sphere_convection_w_m2k,expected_cylinder_convection_w_m2k,expected_latent_heat_j_kg,authority,source_id,atol,rtol")
    index = 0
    for temperature_text in temperatures, pressure_text in pressures
        index += 1
        temperature = bf(temperature_text)
        pressure = bf(pressure_text)
        wind = bf(winds[mod1(index, length(winds))])
        vapour = bf(vapour_pressures[mod1(index, length(vapour_pressures))])
        println(io, join(("physical_v3_" * lpad(string(index), 2, '0'),
            temperature, pressure, wind, vapour, density(temperature, pressure),
            viscosity(temperature), conductivity(temperature),
            diffusivity(temperature, pressure), emissivity(vapour),
            sphere_convection(temperature, pressure, wind),
            cylinder_convection(temperature, pressure, wind), latent(temperature), "analytic",
            "bird_stewart_lightfoot_2002", "1e-14", "2e-12"), ','))
    end
    return String(take!(io))
end

function secondary_indices_csv()
    function heat_index(temperature_c, humidity)
        temperature_f = bf("1.8") * temperature_c + 32
        estimate = bf("0.5") * (
            temperature_f + 61 + bf("1.2") * (temperature_f - 68) +
            bf("0.094") * humidity
        )
        estimate = bf("0.5") * (estimate + temperature_f)
        if estimate < 80
            return (estimate - 32) / bf("1.8")
        end
        temperature_squared = temperature_f^2
        humidity_squared = humidity^2
        result = bf("-42.379") + bf("2.04901523") * temperature_f +
                 bf("10.14333127") * humidity -
                 bf("0.22475541") * temperature_f * humidity -
                 bf("0.00683783") * temperature_squared -
                 bf("0.05481717") * humidity_squared +
                 bf("0.00122874") * temperature_squared * humidity +
                 bf("0.00085282") * temperature_f * humidity_squared -
                 bf("0.00000199") * temperature_squared * humidity_squared
        if humidity < 13 && 80 <= temperature_f <= 112
            result -= (13 - humidity) / 4 *
                      sqrt((17 - abs(temperature_f - 95)) / 17)
        elseif humidity > 85 && 80 <= temperature_f <= 87
            result += (humidity - 85) / 10 * (87 - temperature_f) / 5
        end
        return (result - 32) / bf("1.8")
    end
    function stull(temperature, humidity)
        return temperature * atan(bf("0.151977") * sqrt(humidity + bf("8.313659"))) +
               atan(temperature + humidity) - atan(humidity - bf("1.676331")) +
               bf("0.00391838") * humidity * sqrt(humidity) *
               atan(bf("0.023101") * humidity) - bf("4.686035")
    end
    function humidex_value(temperature, dew_point)
        offset = bf("273.15")
        vapour = bf("6.11") * exp(
            bf("5417.753") * (inv(offset) - inv(dew_point + offset)),
        )
        return temperature + bf("0.5555") * (vapour - 10)
    end

    cases = Any[
        ("wbgt_solar_1", "wbgt_with_solar_load", nothing, nothing, nothing, "20", "30", "25"),
        ("wbgt_solar_2", "wbgt_with_solar_load", nothing, nothing, nothing, "28.2", "36.4", "31"),
        ("wbgt_no_solar_1", "wbgt_without_solar_load", nothing, nothing, nothing, "20", "30", nothing),
        ("wbgt_no_solar_2", "wbgt_without_solar_load", nothing, nothing, nothing, "28.2", "36.4", nothing),
    ]
    for (index, (temperature, humidity)) in enumerate((
        ("20", "0"), ("20", "50"), ("30", "10"), ("32", "70"),
        ("40", "10"), ("30", "90"), ("26.7", "86"), ("44", "40"),
    ))
        push!(cases, ("heat_index_" * string(index), "heat_index_nws",
            temperature, nothing, humidity, nothing, nothing, nothing))
    end
    for (index, (temperature, humidity)) in enumerate((
        ("-20", "5"), ("-20", "99"), ("20", "50"),
        ("30", "70"), ("50", "5"), ("50", "99"),
    ))
        push!(cases, ("stull_" * string(index), "wet_bulb_temperature_stull",
            temperature, nothing, humidity, nothing, nothing, nothing))
    end
    for (index, (temperature, dew_point)) in enumerate((
        ("15", "10"), ("25", "25"), ("30", "20"),
        ("40", "30"), ("0", "-5"), ("-20", "-25"),
    ))
        push!(cases, ("humidex_" * string(index), "humidex",
            temperature, dew_point, nothing, nothing, nothing, nothing))
    end

    io = IOBuffer()
    println(io, "id,formula,air_temperature_c,dew_point_c,relative_humidity_percent,natural_wet_bulb_c,globe_temperature_c,dry_bulb_temperature_c,expected_value,authority,source_id,atol,rtol")
    for (id, formula, air, dew, humidity, wet, globe, dry) in cases
        expected = if formula == "wbgt_with_solar_load"
            bf("0.7") * bf(wet) + bf("0.2") * bf(globe) + bf("0.1") * bf(dry)
        elseif formula == "wbgt_without_solar_load"
            bf("0.7") * bf(wet) + bf("0.3") * bf(globe)
        elseif formula == "heat_index_nws"
            heat_index(bf(air), bf(humidity))
        elseif formula == "wet_bulb_temperature_stull"
            stull(bf(air), bf(humidity))
        else
            humidex_value(bf(air), bf(dew))
        end
        source = formula == "heat_index_nws" ? "nws_heat_index" :
                 formula == "wet_bulb_temperature_stull" ? "stull_2011" :
                 formula == "humidex" ? "eccc_humidex" : "osha_wbgt"
        values = (
            id, formula, something(air, ""), something(dew, ""),
            something(humidity, ""), something(wet, ""), something(globe, ""),
            something(dry, ""), expected, "high_precision", source, "1e-10", "1e-12",
        )
        println(io, join(values, ','))
    end
    return String(take!(io))
end

function failure_csv()
    return """
id,kind,expected_input_status,expected_failure_reason,authority,source_id,atol,rtol
missing_meteorology,public,MissingMeteorology,NotAttempted,invariant,package_contract,0,0
missing_time,public,MissingTime,NotAttempted,invariant,package_contract,0,0
invalid_dew_point,public,InvalidDewPoint,NotAttempted,invariant,package_contract,0,0
invalid_domain,public,InvalidDomain,NotAttempted,invariant,package_contract,0,0
unbracketed,solver,InputAccepted,Unbracketed,invariant,package_contract,0,0
nonfinite_residual,solver,InputAccepted,NonFiniteResidual,invariant,package_contract,0,0
residual_validation_failed,solver,InputAccepted,ResidualValidationFailed,invariant,package_contract,0,0
iteration_limit,solver,InputAccepted,IterationLimit,invariant,package_contract,0,0
not_attempted,solver,InvalidDomain,NotAttempted,invariant,package_contract,0,0
no_failure,solver,InputAccepted,NoFailure,invariant,package_contract,0,0
"""
end

function solar_csv()
    return """
id,time,longitude_deg,latitude_deg,expected_zenith_deg,authority,source_id,atol_deg,rtol
equinox_bengaluru,2024-03-20T06:00:00,77.5946,12.9716,19.147918790,high_precision,nrel_spa_pvlib_0152,2.0,0
equinox_san_francisco,2024-03-20T18:00:00,-122.4194,37.7749,48.995453294,high_precision,nrel_spa_pvlib_0152,2.0,0
summer_sydney,2024-06-21T00:00:00,151.2093,-33.8688,63.703966103,high_precision,nrel_spa_pvlib_0152,2.0,0
summer_iceland,2024-06-21T18:00:00,-21.9426,64.1466,59.297467755,high_precision,nrel_spa_pvlib_0152,2.0,0
southern_high_latitude,2024-12-21T12:00:00,-68.3030,-54.8019,58.387150165,high_precision,nrel_spa_pvlib_0152,2.0,0
winter_new_york,2024-12-21T18:00:00,-74.0060,40.7128,65.939036083,high_precision,nrel_spa_pvlib_0152,2.0,0
leap_before,2024-02-28T12:00:00,0,0,8.640472030,high_precision,nrel_spa_pvlib_0152,2.0,0
leap_day,2024-02-29T12:00:00,0,0,8.271657146,high_precision,nrel_spa_pvlib_0152,2.0,0
leap_after,2024-03-01T12:00:00,0,0,7.901472412,high_precision,nrel_spa_pvlib_0152,2.0,0
common_before,2023-02-28T12:00:00,0,0,8.551524062,high_precision,nrel_spa_pvlib_0152,2.0,0
common_after,2023-03-01T12:00:00,0,0,8.182292524,high_precision,nrel_spa_pvlib_0152,2.0,0
horizon_below,2024-03-20T06:00:00,0,0,91.848178282,high_precision,nrel_spa_pvlib_0152,2.0,0
horizon_near,2024-03-20T06:05:00,0,0,90.597922272,high_precision,nrel_spa_pvlib_0152,2.0,0
horizon_above,2024-09-22T06:00:00,0,0,88.155898267,high_precision,nrel_spa_pvlib_0152,2.0,0
horizon_evening,2024-09-22T18:00:00,0,0,91.893040070,high_precision,nrel_spa_pvlib_0152,2.0,0
"""
end

function outputs()
    return setprecision(BigFloat, PRECISION_BITS) do
        cases = selected_cases()
        reference = reference_csv(cases)
        Dict(
            CASE_PATH => case_definitions(cases),
            joinpath(FIXTURE_ROOT, "liljegren_reference.csv") => reference,
            joinpath(FIXTURE_ROOT, "liljegren_components.csv") => component_csv(reference),
            joinpath(FIXTURE_ROOT, "psychrometrics.csv") => psychrometrics_csv(),
            joinpath(FIXTURE_ROOT, "physical_kernels.csv") => physical_csv(),
            joinpath(FIXTURE_ROOT, "secondary_indices.csv") => secondary_indices_csv(),
            joinpath(FIXTURE_ROOT, "liljegren_failures.csv") => failure_csv(),
            joinpath(FIXTURE_ROOT, "solar_geometry.csv") => solar_csv(),
        )
    end
end

function metadata(generated)
    entries = sort(collect(generated); by = first)
    io = IOBuffer()
    println(io, "schema_version = 4")
    println(io, "fixture_set = \"numerical-conformance-v3\"")
    println(io, "generator = \"validation/generate_fixture_set_v3.jl\"")
    println(io, "generator_revision = \"v2-buck-liljegren\"")
    println(io, "julia_version = \"1.10\"")
    println(io, "precision_bits = $PRECISION_BITS")
    println(io, "timezone = \"UTC\"")
    println(io, "random_seed = 0")
    println(io, "liljegren_reference_rows = $REFERENCE_ROWS")
    println(io, "selection = \"deterministic greedy pairwise then three-way coverage\"")
    for (path, contents) in entries
        relative = replace(relpath(path, REPOSITORY_ROOT), '\\' => '/')
        key = replace(replace(relative, '/' => '_'), '.' => '_')
        println(io)
        println(io, "[files.$key]")
        println(io, "path = \"$relative\"")
        println(io, "sha256 = \"$(bytes2hex(sha256(contents)))\"")
    end
    return String(take!(io))
end

function check_file(path::String, expected::String)
    isfile(path) || error("missing generated fixture: $path")
    actual = replace(read(path, String), "\r\n" => "\n")
    actual == expected || error("$path differs from standalone v3 recomputation")
end

function main(args::Vector{String} = ARGS)
    args == String[] || args == ["--check"] ||
        error("usage: generate_fixture_set_v3.jl [--check]")
    generated = outputs()
    generated[METADATA_PATH] = metadata(generated)
    if args == ["--check"]
        for (path, expected) in generated
            check_file(path, expected)
        end
        return nothing
    end
    for (path, contents) in generated
        mkpath(dirname(path))
        open(path, "w") do io
            write(io, contents)
        end
    end
    return nothing
end

end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && FixtureSetV3Generator.main()
