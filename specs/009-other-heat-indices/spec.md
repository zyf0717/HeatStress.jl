# Other heat indices

## Purpose

Implement selected non-Liljegren heat-stress calculations as independently sourced, idiomatic scalar Julia functions with broadcasting. HeatStressR's export list may inform feature prioritisation privately, but it is not the formula source.

## General rule

Each index is implemented as a scalar function. Users obtain array behaviour with broadcasting:

```julia
wet_bulb_temperature_stull.(temperature, humidity)
```

Optional aligned-array methods may validate dimensions or preallocate output, but must delegate to the scalar formula.

## Proposed public functions

- `wet_bulb_temperature_stull`
- `wbgt_bernard`
- `simplified_wbgt`
- `apparent_temperature`
- `effective_temperature`
- `humidex`
- `discomfort_index`
- `heat_index`
- `relative_humidity_from_dewpoint`
- `vapour_pressure`

Do not add a function merely because HeatStressR exports it. Before implementation, add a source record containing the publication or standard, exact formula/version, valid domain, units and known limitations.

## Formula-source requirements

### Stull wet-bulb approximation

Use Stull's published approximation and cite the original publication. Transcribe coefficients from the publication, not from HeatStressR. Record its valid temperature/humidity range and test behaviour at and outside that range.

### Simplified WBGT

Choose and document one named published formulation. Because several “simplified WBGT” equations circulate with different vapour-pressure units and constants, expose the precise formula and units in the docstring. Do not silently select the HeatStressR variant.

### Apparent and effective temperature

Identify the exact published formulation before coding. If multiple versions exist, either:

- select one canonical version and name/cite it clearly; or
- expose explicitly named variants.

Avoid a generic name whose semantics depend on undocumented coefficients.

### Bernard indoor/shade WBGT

Derive the psychrometric relation from its original publication or an authoritative technical source. Express it as a signed residual where mathematically valid and solve with the shared bracketed solver. Treat saturation as a documented trivial-root case. Do not reproduce an `optimize(abs(residual))` pattern merely because another implementation uses it.

### Humidex, discomfort index and heat index

Use authoritative published/government sources. Heat-index tests must cover every documented piecewise branch and each threshold from the selected source.

## Input validation

- state temperature units explicitly;
- state whether vapour pressure is Pa, hPa or kPa;
- require finite RH and document the accepted domain;
- state wind units for apparent/effective temperature;
- propagate `missing` through explicit methods and broadcasting;
- raise or return a documented status for out-of-domain values instead of silently returning complex/nonsensical results.

## Return types

Simple indices return promoted floating values or `missing`.

Bernard may return:

```julia
struct BernardWBGTResult{T<:AbstractFloat}
    wbgt_c::Union{Missing,T}
    psychrometric_wet_bulb_c::Union{Missing,T}
end
```

## Tests

For each index:

- examples recomputed directly from the cited formula;
- branch and domain boundaries;
- scalar versus broadcast;
- Float32 and Float64;
- missing propagation;
- dimensional/unit sanity checks;
- at least one independently calculated high-precision expected value.

Private black-box comparisons against HeatStressR may be run after these tests pass, but mismatches are investigation prompts rather than automatic failures.

## Acceptance criteria

- every function has an authoritative formula citation;
- no formula is sourced only from software code;
- no simple index requires vector construction;
- scientific fixtures pass with function-specific tolerances;
- public names describe the selected formulation accurately;
- no R dotted names are exported.

## Suggested commit

`feat: implement independently sourced heat stress indices`

