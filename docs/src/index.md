# HeatStress.jl

HeatStress.jl is a pre-release Julia package that independently implements
heat-stress models from published literature.

The implemented public model is Liljegren outdoor WBGT. It supports scalar,
allocating batch, preallocated batch, and diagnostic batch calls. Inputs,
numerical policies, and result diagnostics are documented explicitly; the
remaining heat-index implementations are not public until their formula
selection and validation specifications are complete.

Start with the [public API](api.md), then review the
[Liljegren pipeline](liljegren.md) and [package architecture](architecture.md).
