using Test
using HeatStress

function _globe_balance_fixture(::Type{T} = Float64) where {T<:AbstractFloat}
    air_temperature_k = T(303.15)
    atmospheric_emissivity = HeatStress._atmospheric_emissivity(T(20))
    return HeatStress.GlobeBalance(
        air_temperature_k,
        T(1013.25),
        T(1),
        HeatStress._globe_longwave_term(air_temperature_k, atmospheric_emissivity),
        HeatStress._globe_solar_term(T(800), T(0.7), T(π / 6), T(0.45), T(0.05), T(0.95)),
        T(0.0508),
        T(0.95),
    )
end

function _wet_bulb_balance_fixture(::Type{T} = Float64) where {T<:AbstractFloat}
    air_temperature_k = T(303.15)
    pressure_hpa = T(1013.25)
    vapour_pressure_hpa = T(20)
    atmospheric_emissivity = HeatStress._atmospheric_emissivity(vapour_pressure_hpa)
    return HeatStress.WetBulbBalance(
        air_temperature_k,
        pressure_hpa,
        T(1),
        vapour_pressure_hpa,
        HeatStress._wet_bulb_longwave_term(air_temperature_k, atmospheric_emissivity, T(0.95)),
        HeatStress._wet_bulb_solar_term(T(800), T(0.7), T(π / 6), T(0.45), T(0.4), T(0.007), T(0.0254)),
        true,
        T(0.007),
        T(0.95),
    )
end

function _bisect_root(residual, lower, upper)
    lower_residual = residual(lower)
    upper_residual = residual(upper)
    @assert lower_residual < 0 < upper_residual
    for _ in 1:80
        midpoint = (lower + upper) / 2
        midpoint_residual = residual(midpoint)
        if midpoint_residual < 0
            lower = midpoint
        else
            upper = midpoint
        end
    end
    return (lower + upper) / 2
end

function _residual_allocations(globe, wet_bulb)
    HeatStress._globe_energy_residual_k4(320.0, globe)
    HeatStress._natural_wet_bulb_residual(295.0, wet_bulb)
    return (
        @allocated(HeatStress._globe_energy_residual_k4(320.0, globe)),
        @allocated(HeatStress._natural_wet_bulb_residual(295.0, wet_bulb)),
    )
end

@testset "physical kernels" begin
    @testset "bounded pressure-enhanced Buck kernel" begin
        for T in (Float32, Float64, BigFloat)
            pressure = T(1010)
            minimum = T(-40)
            maximum = T(50)
            at_minimum = HeatStress._buck_saturation_vapour_pressure_hpa(minimum, pressure)
            below_zero = HeatStress._buck_saturation_vapour_pressure_hpa(prevfloat(zero(T)), pressure)
            at_zero = HeatStress._buck_saturation_vapour_pressure_hpa(zero(T), pressure)
            at_maximum = HeatStress._buck_saturation_vapour_pressure_hpa(maximum, pressure)

            @test at_minimum isa T
            @test at_minimum ≈ T(0.19114543808424305) rtol = T(2e-6)
            @test at_zero ≈ T(6.13773781466) rtol = T(2e-6)
            @test at_maximum ≈ T(124.21113127862339) rtol = T(2e-6)
            @test below_zero <= at_zero
            @test isnan(HeatStress._buck_saturation_vapour_pressure_hpa(
                prevfloat(minimum), pressure,
            ))
            @test isnan(HeatStress._buck_saturation_vapour_pressure_hpa(
                nextfloat(maximum), pressure,
            ))
            @test HeatStress._buck_saturation_vapour_pressure_hpa(zero(T), T(1100)) >
                  HeatStress._buck_saturation_vapour_pressure_hpa(zero(T), T(700))
        end
        @test isnan(HeatStress._buck_saturation_vapour_pressure_hpa(0.0, 0.0))
        @test isnan(HeatStress._buck_saturation_vapour_pressure_hpa(NaN, 1010.0))
    end

    @testset "air-property fixtures" begin
        # Independent values from the equations selected in specs/005 research.
        fixtures = [
            (270.0, 1.7009893731884383e-5, 0.0238172675384395, 2.0641141526259348e-5),
            (300.0, 1.8447812854633166e-5, 0.0260692623386395, 2.6395609490249917e-5),
            (340.0, 2.0267253611046905e-5, 0.0289304610322395, 3.535106307695993e-5),
        ]
        for (temperature_k, viscosity, conductivity, diffusivity) in fixtures
            @test HeatStress._air_viscosity(temperature_k) ≈ viscosity rtol = 2e-14
            @test HeatStress._air_thermal_conductivity(temperature_k) ≈ conductivity rtol = 2e-14
            @test HeatStress._air_diffusivity(temperature_k, 1013.25) ≈ diffusivity rtol = 2e-14
        end
        @test HeatStress._diffusivity_coefficient(300.0, 1013.25) ≈ 0.6873250243931388 rtol = 2e-14
        @test HeatStress._latent_heat_vaporization(300.0) ≈ 2.43836255e6 rtol = 2e-14
        @test HeatStress._atmospheric_emissivity(1.0) == 0.575
        @test HeatStress._atmospheric_emissivity(6.0) ≈ 0.7427322967021793 rtol = 2e-14
        @test HeatStress._atmospheric_emissivity(20.0) ≈ 0.8821232576647747 rtol = 2e-14
        @test HeatStress._atmospheric_emissivity(40.0) ≈ 0.9739430385554602 rtol = 2e-14
    end

    @testset "sphere and cylinder convection fixtures" begin
        fixtures = [
            (270.0, 0.0, 0.9376876983637599, 0.0),
            (270.0, 0.13, 6.609797999200696, 10.561658638404634),
            (270.0, 3.0, 28.18562421791884, 69.444661937256),
            (300.0, 0.0, 1.0263489109700592, 0.0),
            (300.0, 0.13, 6.664671414943171, 10.294643671635544),
            (300.0, 3.0, 28.11197410453677, 67.68899412651638),
            (340.0, 0.0, 1.1389945288283267, 0.0),
            (340.0, 0.13, 6.727733431987638, 9.972122883164483),
            (340.0, 3.0, 27.986427808675376, 65.56836630754215),
        ]
        for (temperature_k, wind_speed_m_s, sphere, cylinder) in fixtures
            @test HeatStress._heat_transfer_sphere_air(temperature_k, 1013.25, wind_speed_m_s, 0.0508) ≈
                  sphere rtol = 2e-14
            @test HeatStress._heat_transfer_cylinder_air(temperature_k, 1013.25, wind_speed_m_s, 0.007) ≈
                  cylinder rtol = 2e-14
        end
    end

    @testset "solar forcing horizon policy" begin
        threshold = HeatStress.MINIMUM_DIRECT_SOLAR_ELEVATION_RAD
        active = HeatStress._direct_solar_geometry(pi / 2 - threshold - 1e-6)
        clipped = HeatStress._direct_solar_geometry(pi / 2 - threshold + 1e-6)
        at_horizon = HeatStress._direct_solar_geometry(pi / 2)
        below_horizon = HeatStress._direct_solar_geometry(pi / 2 + 1e-6)
        @test 0 < active[1] < 60
        @test 0 < active[2] < 40
        @test active[3:4] == (true, false)
        @test clipped == (0.0, 0.0, false, true)
        @test at_horizon == (0.0, 0.0, false, false)
        @test below_horizon == (0.0, 0.0, false, false)
        @test HeatStress._direct_solar_geometry(deg2rad(89.5)) ==
              (0.0, 0.0, false, true)

        globe_day = HeatStress._globe_solar_term(800.0, 0.7, pi / 6, 0.45, 0.05, 0.95)
        globe_clipped = HeatStress._globe_solar_term(800.0, 0.7, pi / 2 - threshold / 2, 0.45, 0.05, 0.95)
        wet_day = HeatStress._wet_bulb_solar_term(800.0, 0.7, pi / 6, 0.45, 0.4, 0.007, 0.0254)
        wet_clipped = HeatStress._wet_bulb_solar_term(800.0, 0.7, pi / 2 - threshold / 2, 0.45, 0.4, 0.007, 0.0254)
        @test globe_day > globe_clipped > 0
        @test wet_day > wet_clipped > 0
    end

    @testset "residual separation and sign brackets" begin
        globe = _globe_balance_fixture()
        @test isbitstype(typeof(globe))
        # Independently retained reference values for the documented
        # fourth-power balance; the energy residual must not take a fourth root.
        for (candidate_k, radicand_k4, energy_residual_k4) in (
            (320.0, 1.0878865385319973e10, -3.93105385319973e8),
            (325.0, 9.332922338171188e9, 1.8237182868288116e9),
            (360.0, -1.4794397468130836e9, 1.8275599746813084e10),
        )
            @test HeatStress._globe_equilibrium_radicand_k4(candidate_k, globe) ≈ radicand_k4 rtol = 2e-14
            @test HeatStress._globe_energy_residual_k4(candidate_k, globe) ≈ energy_residual_k4 rtol = 2e-14
        end
        @test HeatStress._globe_energy_residual_k4(320.0, globe) < 0
        @test HeatStress._globe_energy_residual_k4(325.0, globe) > 0
        globe_root = _bisect_root(t -> HeatStress._globe_energy_residual_k4(t, globe), 320.0, 325.0)
        @test globe_root ≈ 320.89173511564036 atol = 1e-11
        @test abs(HeatStress._globe_fixed_point_residual_k(globe_root, globe)) < 1e-11
        @test isfinite(HeatStress._globe_energy_residual_k4(360.0, globe))
        @test isnan(HeatStress._globe_fixed_point_residual_k(360.0, globe))

        wet_bulb = _wet_bulb_balance_fixture()
        @test isbitstype(typeof(wet_bulb))
        @test HeatStress._globe_longwave_term(303.15, 0.8) ==
              (0.8 + 1.0) * 303.15^4 / 2
        @test HeatStress._wet_bulb_longwave_term(303.15, 0.8, 0.95) ==
              HeatStress.STEFAN_BOLTZMANN * 0.95 * (0.8 + 1.0) * 303.15^4 / 2
        film_temperature_k = (295.0 + wet_bulb.air_temperature_k) / 2
        @test HeatStress._heat_transfer_cylinder_air(
            film_temperature_k,
            wet_bulb.pressure_hpa,
            wet_bulb.effective_wind_m_s,
            wet_bulb.wick_diameter_m,
        ) > 0
        @test HeatStress._natural_wet_bulb_residual(295.0, wet_bulb) < 0
        @test HeatStress._natural_wet_bulb_residual(300.0, wet_bulb) > 0
        wet_root = _bisect_root(t -> HeatStress._natural_wet_bulb_residual(t, wet_bulb), 295.0, 300.0)
        @test abs(HeatStress._natural_wet_bulb_residual(wet_root, wet_bulb)) < 1e-11
        @test isnan(HeatStress._natural_wet_bulb_residual(NaN, wet_bulb))
    end

    @testset "Float32 inference and allocations" begin
        globe = _globe_balance_fixture(Float32)
        wet_bulb = _wet_bulb_balance_fixture(Float32)
        @test @inferred(HeatStress._air_viscosity(300f0)) isa Float32
        @test @inferred(HeatStress._air_thermal_conductivity(300f0)) isa Float32
        @test @inferred(HeatStress._air_diffusivity(300f0, 1013.25f0)) isa Float32
        @test @inferred(HeatStress._heat_transfer_sphere_air(300f0, 1013.25f0, 1f0, 0.0508f0)) isa Float32
        @test @inferred(HeatStress._heat_transfer_cylinder_air(300f0, 1013.25f0, 1f0, 0.007f0)) isa Float32
        @test @inferred(HeatStress._globe_energy_residual_k4(320f0, globe)) isa Float32
        @test @inferred(HeatStress._natural_wet_bulb_residual(295f0, wet_bulb)) isa Float32

        globe64 = _globe_balance_fixture()
        wet_bulb64 = _wet_bulb_balance_fixture()
        @test @inferred(HeatStress._air_viscosity(300.0)) isa Float64
        @test @inferred(HeatStress._air_thermal_conductivity(300.0)) isa Float64
        @test @inferred(HeatStress._air_diffusivity(300.0, 1013.25)) isa Float64
        @test @inferred(HeatStress._heat_transfer_sphere_air(300.0, 1013.25, 1.0, 0.0508)) isa Float64
        @test @inferred(HeatStress._heat_transfer_cylinder_air(300.0, 1013.25, 1.0, 0.007)) isa Float64
        @test @inferred(HeatStress._globe_energy_residual_k4(320.0, globe64)) isa Float64
        @test @inferred(HeatStress._natural_wet_bulb_residual(295.0, wet_bulb64)) isa Float64

        globe_allocations, wet_bulb_allocations = _residual_allocations(globe64, wet_bulb64)
        @test globe_allocations == 0
        @test wet_bulb_allocations == 0
    end
end
