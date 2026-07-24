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
        HeatStress._globe_solar_term(T(800), T(0.7), T(30), T(0.45), T(0.05), T(0.95)),
        T(0.0508),
        T(0.95),
    )
end

function _wet_bulb_balance_fixture(::Type{T} = Float64) where {T<:AbstractFloat}
    air_temperature_k = T(303.15)
    pressure_hpa = T(1013.25)
    vapour_pressure_hpa = T(20)
    atmospheric_emissivity = HeatStress._atmospheric_emissivity(vapour_pressure_hpa)
    density = HeatStress._air_density(air_temperature_k, pressure_hpa)
    viscosity = HeatStress._air_viscosity(air_temperature_k)
    return HeatStress.WetBulbBalance(
        air_temperature_k,
        pressure_hpa,
        T(1),
        vapour_pressure_hpa,
        density,
        viscosity,
        HeatStress._diffusivity_coefficient(air_temperature_k, pressure_hpa, density, viscosity),
        HeatStress._wet_bulb_longwave_term(air_temperature_k, atmospheric_emissivity, T(0.95)),
        HeatStress._wet_bulb_solar_term(T(800), T(0.7), T(30), T(0.45), T(0.4), T(0.007), T(0.0254)),
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
        near_horizon = HeatStress._direct_solar_geometry(89.999)
        at_horizon = HeatStress._direct_solar_geometry(90.0)
        below_horizon = HeatStress._direct_solar_geometry(90.001)
        @test near_horizon[1] > 10_000
        @test near_horizon[2] > 10_000
        @test near_horizon[3]
        @test at_horizon == (0.0, 0.0, false)
        @test below_horizon == (0.0, 0.0, false)

        globe_day = HeatStress._globe_solar_term(800.0, 0.7, 30.0, 0.45, 0.05, 0.95)
        globe_night = HeatStress._globe_solar_term(800.0, 0.7, 90.0, 0.45, 0.05, 0.95)
        wet_day = HeatStress._wet_bulb_solar_term(800.0, 0.7, 30.0, 0.45, 0.4, 0.007, 0.0254)
        wet_night = HeatStress._wet_bulb_solar_term(800.0, 0.7, 90.0, 0.45, 0.4, 0.007, 0.0254)
        @test globe_day > globe_night > 0
        @test wet_day > wet_night > 0
    end

    @testset "residual separation and sign brackets" begin
        globe = _globe_balance_fixture()
        @test isbitstype(typeof(globe))
        @test HeatStress._globe_energy_residual_k4(320.0, globe) < 0
        @test HeatStress._globe_energy_residual_k4(325.0, globe) > 0
        globe_root = _bisect_root(t -> HeatStress._globe_energy_residual_k4(t, globe), 320.0, 325.0)
        @test abs(HeatStress._globe_fixed_point_residual_k(globe_root, globe)) < 1e-11
        @test isnan(HeatStress._globe_energy_residual_k4(360.0, globe))

        wet_bulb = _wet_bulb_balance_fixture()
        @test isbitstype(typeof(wet_bulb))
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
        globe_allocations, wet_bulb_allocations = _residual_allocations(globe64, wet_bulb64)
        @test globe_allocations == 0
        @test wet_bulb_allocations == 0
    end
end
