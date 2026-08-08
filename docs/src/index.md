# HeatStress.jl

HeatStress.jl is an independent MIT-licensed Julia package for Liljegren and
RCC estimated-WBGT models plus selected direct heat measures.

Liljegren supports scalar, allocating batch, preallocated batch, and diagnostic
batch calls. Measured-component WBGT, NWS heat index, Stull wet-bulb
temperature, and humidex are scalar formulas designed for ordinary
broadcasting. Inputs, applicability, numerical policies, and limitations are
documented explicitly.

Start with the [public API](api.md), then review
[secondary measures](secondary-measures.md), [inputs and policies](inputs.md),
the [Liljegren pipeline](liljegren.md), [RCC estimated WBGT](rcc-wbgt.md), and
[numerical behaviour](numerical-behaviour.md).
