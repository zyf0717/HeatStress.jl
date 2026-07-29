using Test

_fahrenheit_as_celsius(value) = (value - 32) * 5 / 9

@testset "secondary heat measures" begin
    @testset "measured-component WBGT" begin
        @test wbgt_with_solar_load(20.0, 30.0, 25.0) == 22.5
        @test wbgt_without_solar_load(20.0, 30.0) == 23.0
        @test wbgt_with_solar_load(28.2, 36.4, 31.0) ≈ 30.12 atol = 1e-12
        @test wbgt_without_solar_load(28.2, 36.4) ≈ 30.66 atol = 1e-12

        @test wbgt_with_solar_load(20f0, 30f0, 25f0) isa Float32
        @test wbgt_without_solar_load(20f0, 30f0) isa Float32
        @test wbgt_with_solar_load(20f0, 30.0, 25f0) isa Float64
        @test wbgt_without_solar_load(20, 30) isa Float64

        @test wbgt_with_solar_load(missing, 30.0, 25.0) === missing
        @test wbgt_with_solar_load(20.0, missing, 25.0) === missing
        @test wbgt_with_solar_load(20.0, 30.0, missing) === missing
        @test wbgt_without_solar_load(missing, 30.0) === missing
        @test wbgt_without_solar_load(20.0, missing) === missing

        @test_throws DomainError wbgt_with_solar_load(NaN, 30.0, 25.0)
        @test_throws DomainError wbgt_with_solar_load(20.0, Inf, 25.0)
        @test_throws DomainError wbgt_with_solar_load(20.0, 30.0, -Inf)
        @test_throws DomainError wbgt_without_solar_load(NaN, 30.0)

        wet = Union{Missing,Float64}[20, missing, 24]
        @test isequal(
            wbgt_with_solar_load.(wet, 30.0, 25.0),
            Union{Missing,Float64}[
                wbgt_with_solar_load(20.0, 30.0, 25.0),
                missing,
                wbgt_with_solar_load(24.0, 30.0, 25.0),
            ],
        )
        @test isequal(
            wbgt_without_solar_load.(wet, 30.0),
            Union{Missing,Float64}[
                wbgt_without_solar_load(20.0, 30.0),
                missing,
                wbgt_without_solar_load(24.0, 30.0),
            ],
        )
    end

    @testset "NWS heat index" begin
        @test heat_index_nws(20.0, 50.0) ≈ 19.680555555555557 atol = 1e-12
        @test heat_index_nws(32.0, 70.0) ≈ 40.409273679555554 atol = 1e-12
        @test heat_index_nws(40.0, 10.0) ≈ 36.70530588031804 atol = 1e-12
        @test heat_index_nws(30.0, 90.0) ≈ 40.774647 atol = 1e-12

        # The NWS procedure switches to Rothfusz when the averaged simple
        # estimate reaches 80°F.
        humidity = 50.0
        transition_f = (80.0 + 5.15 - 0.0235 * humidity) / 1.05
        below_transition_f = transition_f - 1e-10
        above_transition_f = transition_f + 1e-10
        @test HeatStress._simple_heat_index_f(below_transition_f, humidity) < 80
        @test HeatStress._simple_heat_index_f(above_transition_f, humidity) >= 80
        below = heat_index_nws(_fahrenheit_as_celsius(below_transition_f), humidity)
        above = heat_index_nws(_fahrenheit_as_celsius(above_transition_f), humidity)
        @test below != above

        # Adjustment boundaries are strict in RH and inclusive in temperature.
        base = 100.0
        @test HeatStress._adjust_heat_index_f(base, 80.0, 12.0) < base
        @test HeatStress._adjust_heat_index_f(base, prevfloat(112.0), 12.0) < base
        @test HeatStress._adjust_heat_index_f(base, 112.0, 12.0) == base
        @test HeatStress._adjust_heat_index_f(base, prevfloat(80.0), 12.0) == base
        @test HeatStress._adjust_heat_index_f(base, nextfloat(112.0), 12.0) == base
        @test HeatStress._adjust_heat_index_f(base, 95.0, prevfloat(13.0)) == base
        @test HeatStress._adjust_heat_index_f(base, 95.0, 13.0) == base
        @test HeatStress._adjust_heat_index_f(base, 95.0, nextfloat(13.0)) == base
        @test HeatStress._adjust_heat_index_f(base, 80.0, 86.0) > base
        @test HeatStress._adjust_heat_index_f(base, prevfloat(87.0), 86.0) == base
        @test HeatStress._adjust_heat_index_f(base, 87.0, 86.0) == base
        @test HeatStress._adjust_heat_index_f(base, nextfloat(87.0), 86.0) == base
        @test HeatStress._adjust_heat_index_f(base, 85.0, prevfloat(85.0)) == base
        @test HeatStress._adjust_heat_index_f(base, 85.0, 85.0) == base
        @test HeatStress._adjust_heat_index_f(base, 85.0, nextfloat(85.0)) == base

        @test heat_index_nws(32f0, 70f0) isa Float32
        @test heat_index_nws(32f0, 70.0) isa Float64
        @test heat_index_nws(missing, 70.0) === missing
        @test heat_index_nws(32.0, missing) === missing
        @test isequal(
            heat_index_nws.(Union{Missing,Float64}[20, missing], 50.0),
            Union{Missing,Float64}[heat_index_nws(20.0, 50.0), missing],
        )

        for temperature in (NaN, Inf, -Inf)
            @test_throws DomainError heat_index_nws(temperature, 50.0)
        end
        for humidity_value in (NaN, Inf, -Inf, prevfloat(0.0), nextfloat(100.0))
            @test_throws DomainError heat_index_nws(30.0, humidity_value)
        end
        @test isfinite(heat_index_nws(30.0, 0.0))
        @test isfinite(heat_index_nws(30.0, 100.0))
    end

    @testset "Stull wet-bulb approximation" begin
        @test wet_bulb_temperature_stull(20.0, 50.0) ≈
              13.69934196898814 atol = 1e-12
        @test wet_bulb_temperature_stull(30.0, 70.0) ≈
              25.595662363342065 atol = 1e-12

        for (temperature, humidity) in ((-20.0, 5.0), (-20.0, 99.0), (50.0, 5.0), (50.0, 99.0))
            @test isfinite(wet_bulb_temperature_stull(temperature, humidity))
        end
        @test_throws DomainError wet_bulb_temperature_stull(prevfloat(-20.0), 50.0)
        @test_throws DomainError wet_bulb_temperature_stull(nextfloat(50.0), 50.0)
        @test_throws DomainError wet_bulb_temperature_stull(20.0, prevfloat(5.0))
        @test_throws DomainError wet_bulb_temperature_stull(20.0, nextfloat(99.0))
        @test_throws DomainError wet_bulb_temperature_stull(NaN, 50.0)
        @test_throws DomainError wet_bulb_temperature_stull(20.0, Inf)

        @test wet_bulb_temperature_stull(20f0, 50f0) isa Float32
        @test wet_bulb_temperature_stull(20f0, 50.0) isa Float64
        @test wet_bulb_temperature_stull(missing, 50.0) === missing
        @test wet_bulb_temperature_stull(20.0, missing) === missing
        @test isequal(
            wet_bulb_temperature_stull.(
                Union{Missing,Float64}[20, missing], 50.0,
            ),
            Union{Missing,Float64}[wet_bulb_temperature_stull(20.0, 50.0), missing],
        )
    end

    @testset "ECCC humidex" begin
        @test humidex(30.0, 20.0) ≈ 37.57931098581259 atol = 1e-12
        @test humidex(15.0, 10.0) ≈ 16.283232431406564 atol = 1e-12
        @test humidex(25.0, 25.0) > 25.0

        @test humidex(30f0, 20f0) isa Float32
        @test humidex(30f0, 20.0) isa Float64
        @test humidex(missing, 20.0) === missing
        @test humidex(30.0, missing) === missing
        @test isequal(
            humidex.(Union{Missing,Float64}[30, missing], 20.0),
            Union{Missing,Float64}[humidex(30.0, 20.0), missing],
        )

        @test_throws DomainError humidex(NaN, 20.0)
        @test_throws DomainError humidex(30.0, Inf)
        @test_throws DomainError humidex(-273.15, -273.15)
        @test_throws DomainError humidex(30.0, 30.1)
    end
end
