"""
    wbgt_with_solar_load(
        natural_wet_bulb_c,
        globe_temperature_c,
        dry_bulb_temperature_c,
    )

Calculate measured-component WBGT in degrees Celsius for an environment with
solar load:

`WBGT = 0.7 natural_wet_bulb_c + 0.2 globe_temperature_c + 0.1 dry_bulb_temperature_c`.

The equation is published by the US Occupational Safety and Health
Administration in its Technical Manual, Section III, Chapter 4. Inputs must be
finite temperatures in degrees Celsius. A `missing` input returns `missing`.
"""
@inline function wbgt_with_solar_load(
        natural_wet_bulb_c::_MaybeReal,
        globe_temperature_c::_MaybeReal,
        dry_bulb_temperature_c::_MaybeReal,
    )
    any(ismissing, (natural_wet_bulb_c, globe_temperature_c, dry_bulb_temperature_c)) &&
        return missing
    wet, globe, dry = promote(
        float(natural_wet_bulb_c),
        float(globe_temperature_c),
        float(dry_bulb_temperature_c),
    )
    _require_finite(wet, "natural_wet_bulb_c")
    _require_finite(globe, "globe_temperature_c")
    _require_finite(dry, "dry_bulb_temperature_c")
    T = typeof(wet)
    return convert(T, 7 // 10) * wet +
           convert(T, 1 // 5) * globe +
           convert(T, 1 // 10) * dry
end

"""
    wbgt_without_solar_load(natural_wet_bulb_c, globe_temperature_c)

Calculate measured-component WBGT in degrees Celsius indoors or outdoors
without solar load:

`WBGT = 0.7 natural_wet_bulb_c + 0.3 globe_temperature_c`.

The equation is published by the US Occupational Safety and Health
Administration in its Technical Manual, Section III, Chapter 4. Inputs must be
finite temperatures in degrees Celsius. A `missing` input returns `missing`.
"""
@inline function wbgt_without_solar_load(
        natural_wet_bulb_c::_MaybeReal,
        globe_temperature_c::_MaybeReal,
    )
    any(ismissing, (natural_wet_bulb_c, globe_temperature_c)) && return missing
    wet, globe = promote(float(natural_wet_bulb_c), float(globe_temperature_c))
    _require_finite(wet, "natural_wet_bulb_c")
    _require_finite(globe, "globe_temperature_c")
    T = typeof(wet)
    return convert(T, 7 // 10) * wet + convert(T, 3 // 10) * globe
end
