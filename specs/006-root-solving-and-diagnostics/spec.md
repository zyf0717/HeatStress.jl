# Root solving and diagnostics

## Purpose

Implement one deterministic, package-owned safeguarded bracketed solver that both Liljegren components use. Separate root location from final residual acceptance.

## Solver API

Internal API concept:

```julia
_solve_bracketed(
    residual,
    initial_lower,
    initial_upper,
    expansion_policy,
    minimum,
    maximum,
    config::SolverConfig,
)
```

Return a concrete internal result containing:

- candidate root;
- convergence of root location;
- final bracket and endpoint residuals;
- iterations;
- evaluations;
- location failure category.

The component wrapper then computes the model-specific validation residual and changes the final status to `ResidualValidationFailed` if needed.

## Bracketing policies

Implement component-specific bracket expansion as strategy functions or types.

### Globe

Initial bracket, in Kelvin:

```text
lower = air_temperature_k - 2
upper = air_temperature_k + 10
minimum = air_temperature_k - 200
maximum = air_temperature_k + 200
```

Choose bracket-expansion direction from the residual mathematics and verify it with sign/monotonicity tests:

- if both finite endpoint residuals have the same sign;
- two negative values expand the lower bound;
- two positive values expand the upper bound;
- expansion width follows the current bracket width;
- stop at physical search bounds.

Verify sign-direction statements against the cited source before coding.

### Natural wet bulb

Initial bracket:

```text
lower = dew_point_k - 1
upper = air_temperature_k + 1
minimum = air_temperature_k - 100
maximum = air_temperature_k + 100
```

Expand lower by up to 10 K and then upper by up to 10 K per cycle while the endpoints remain finite, same-signed and within bounds.

## Root location algorithm

Start with deterministic bisection after a valid sign-changing bracket is found.

Algorithm:

1. evaluate both endpoints and count evaluations;
2. classify non-finite endpoint as `NonFiniteResidual`;
3. return an endpoint immediately if its residual is exactly zero;
4. if no sign change after expansion, classify `Unbracketed`;
5. repeatedly evaluate midpoint;
6. update the sign-changing half-bracket;
7. stop when bracket width is at most `root_tolerance_k` or midpoint residual is exactly zero;
8. if `maximum_iterations` is reached, classify `IterationLimit` and retain the last midpoint as candidate;
9. do not mark final component success until model-specific validation residual passes.

Do not use minimisation of absolute residual. The equation is signed and must be solved as a root problem.

A faster safeguarded interpolation method may replace bisection only after:

- bisection and residual-validation tests pass;
- the replacement has property tests;
- diagnostic semantics remain stable;
- benchmarks show a material benefit.

## Final validation

A candidate is accepted only when:

```julia
isfinite(candidate) && isfinite(validation_residual) &&
abs(validation_residual) <= residual_tolerance_k
```

Location tolerance and residual tolerance are independent. Increasing residual tolerance must not convert an unbracketed or non-finite solve into success.

## Diagnostic semantics

Preserve these implementation-independent fields:

- `converged`;
- `reason`;
- accepted value;
- candidate value;
- final validation residual;
- evaluations and iterations;
- initial/final brackets;
- endpoint residuals;
- root and residual tolerances.

Do not expose implementation-specific batch bookkeeping fields in v0.1:

- `batch_iterations`;
- `batch_evaluations`;
- `fallback_evaluations`;
- `used_fallback`;
- `fallback_count`;
- `engine="scalar"/"batch"`.

The Julia scalar solver is canonical, so a scalar fallback concept is not required.

## Warning policy

Scalar diagnostic functions do not warn on expected numerical failure; they return structured failure. Value-only scalar functions may either return `missing` silently or issue one concise warning, but choose one policy package-wide. Recommended: return `missing` without warning for scalar calls.

Batch value-only calls should issue at most one aggregate warning per call when attempted rows fail, and no warning for rows not attempted due to missing input. Diagnostic batch calls should not warn because details are explicitly requested.

Implement warning aggregation outside the solver.

## Tests

Create generic root-solver tests:

- linear root;
- nonlinear monotonic root;
- root exactly at lower/upper endpoint;
- initial valid bracket;
- bracket recovered by expansion;
- unbracketed finite function;
- non-finite endpoint;
- non-finite interior;
- iteration limit;
- root tolerance independent of residual tolerance;
- deterministic evaluations and final bracket;
- Float32 and Float64.

Component tests:

- ordinary globe root;
- ordinary natural wet-bulb root;
- a deliberately constructed unbracketed globe case;
- known failure fixture categories;
- candidate retained but accepted value missing after residual validation failure.

## Acceptance criteria

- no solver dependency is required;
- all failure paths return structured results, not partially populated dictionaries;
- evaluation counts include every residual call exactly once;
- successful roots lie inside final brackets;
- accepted residual magnitude is at or below configured tolerance;
- failure categories match the documented solver contract and independent fixtures.

## Suggested commit

`feat: add safeguarded root solver and diagnostics`

