# Numerical behaviour

The globe and natural-wet-bulb balances are solved independently with a
bracket-preserving bisection method. Root-location tolerance and final physical
residual tolerance are separate `SolverConfig` controls. A candidate is
accepted only after its component residual passes the configured Kelvin-scale
tolerance.

Diagnostics distinguish unbracketed searches, non-finite residuals,
residual-validation failures, iteration limits, and inputs that were not
attempted. Value-only results use `missing` for a failed component and for
complete WBGT unless both components are accepted. `diagnose_liljegren` and
`diagnose_liljegren_batch` expose the classification, brackets, residuals,
iterations, and input-normalisation flags.

Wind diagnostics preserve three distinct stages: supplied wind, nonnegative
wind converted to 2 m, and the post-floor wind consumed by both component
balances. Negative-input clamping and minimum-floor application therefore
remain independently observable. The no-adjustment default preserves the
released numerical path.

Irradiance resolution does not cap a supplied GHI against clear-sky or
top-of-atmosphere estimates. The `0.85` clearness cap applies only inside the
opt-in empirical partition relation. Redundant measured components are
accepted within
`max(irradiance_closure_atol_w_m2,
irradiance_closure_kt_tolerance * I0h)` and otherwise rejected before solving.

No numerical failure is silently converted into a plausible WBGT value. Tighten
tolerances only with care: they affect convergence work and can expose
floating-point representation limits without changing the scientific model.
