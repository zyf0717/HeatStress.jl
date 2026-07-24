# HeatStress.jl

HeatStress.jl is an independent MIT-licensed Julia implementation of the
Liljegren outdoor WBGT model.

The implemented public model is Liljegren outdoor WBGT. It supports scalar,
allocating batch, preallocated batch, and diagnostic batch calls. Inputs,
numerical policies, and result diagnostics are documented explicitly; the
remaining heat-index implementations are not public until their formula
selection and validation specifications are complete.

Start with the [public API](api.md), then review [inputs and policies](inputs.md),
the [Liljegren pipeline](liljegren.md), and [numerical behaviour](numerical-behaviour.md).
