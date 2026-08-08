# Architecture

`HeatStress.jl` keeps public boundaries, input policy, physical kernels,
numerical solving, and result materialisation separate. Constants and policy
types are immutable; no calculation path uses global mutable state.

## Scalar execution flow

```text
public scalar API
  -> common floating type + typed configuration
  -> timestamp/coordinate validation and solar zenith
  -> meteorology normalisation and solar policy
  -> globe and natural-wet-bulb balance construction
  -> independent bracketed component solves + residual validation
  -> value or diagnostic result materialisation
```

The two component solves are independent. WBGT is materialised only when both
validated component values are available; diagnostics retain a valid component
when the other one fails.

## Batch execution flow

```text
public batch API
  -> validate all shapes, output types, and aliases before mutation
  -> promote one calculation type and convert configuration once
  -> ordinal row access (scalar expansion or vector inputs)
  -> canonical scalar time-based row execution
  -> ordinal writes to caller outputs or newly allocated result vectors
```

`threaded=true` partitions rows across Julia threads. Rows write only their
own output positions, and the same typed row path supplies serial and threaded
execution.

## RCC execution flow

```text
named RCC scalar/batch API
  -> promote and validate native Ta/RH/wind/GHI/pressure inputs
  -> NWS fixed-iteration psychrometric wet bulb
  -> RCC-NWS or RCCNL natural wet bulb
  -> shared solar geometry + selected direct partition
  -> Dim228 or Dim167L direct globe calculation
  -> WBGTResult / WBGTBatchResult materialisation
```

RCC coefficients remain private and model-local. The non-iterative component
kernels do not use Liljegren solver diagnostics, configuration, wind-height
policy, or clear-sky fallback. Scalar and batch entry points share the same
typed RCC row engine; the public surface does not introduce a model hierarchy.

## Direct-formula execution

Measured WBGT, NWS heat index, Stull wet bulb, and humidex are independent
scalar formula families. Each promotes inputs once, validates its native
domain, evaluates with coefficients converted to the promoted type, and
returns a value or `missing`. Broadcasting supplies array behavior without a
parallel batch abstraction.
