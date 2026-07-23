# Performance, quality and CI

## Purpose

Optimise only after correctness, and enforce package quality across platforms.

## Benchmark contract

Use `BenchmarkTools.jl`. Separate setup from timed code. Precompile before measurement. Do not include fixture generation, CSV loading or compilation in core timings.

Benchmark groups:

1. solar geometry scalar;
2. solar geometry fixed/grouped/unique batch;
3. component scalar solves;
4. Liljegren scalar repeated loop;
5. allocating serial batch;
6. preallocated serial batch;
7. preallocated threaded batch;
8. value-only versus diagnostic APIs;
9. simple indices broadcast.

Row sizes:

- 1;
- 100;
- 1,000;
- 10,000;
- 87,600;
- 876,000;
- optional 1,000,000.

Coordinate modes:

- fixed station;
- grouped locations with repeated timestamps;
- unique `(time, lon, lat)` triplets.

## Comparison baselines

Public benchmark baselines must include:

- repeated calls to the public scalar Julia API;
- a tight loop over the internal scalar kernel;
- allocating serial batch;
- preallocated serial batch;
- threaded batch at multiple thread counts;
- solar preprocessing on and off where applicable.

Optional HeatStressR comparisons belong in a private benchmark workspace. They may inform optimisation priorities, but public performance claims should be published only when the comparison script, inputs and settings can be shared without copying GPL source or relying on private material. Use identical data, pressure, direct fraction, timestamp mode, output validation and warm-up policy.

## Optimisation order

1. run `@code_warntype`/JET;
2. remove type instability;
3. remove per-row containers and closures;
4. add/prefer `!` interfaces;
5. precompute solar geometry if profiling supports it;
6. reduce repeated invariant calculations in residuals;
7. consider inlining small kernels;
8. consider `@simd` only on simple independent loops after correctness;
9. consider an advanced batch solver only if scalar-loop residual solving remains the dominant bottleneck.

Do not use `@fastmath` in the production scientific path. A separately named approximate mode is out of scope for v0.1.

## Allocation targets

After compilation:

- direct scalar physical kernels: zero allocations;
- scalar value-only Liljegren: target zero allocations for `DateTime`, or document a small fixed count;
- preallocated batch: allocations should be constant or limited to optional precomputed zenith/status arrays, not proportional per-row objects;
- allocating batch: allocations dominated by output arrays;
- diagnostics: proportional to required diagnostic arrays only.

Add allocation regression tests with conservative thresholds on one supported Julia version. Avoid brittle exact byte counts across versions.

## Quality tooling

### Aqua

Check:

- ambiguities;
- undefined exports;
- stale dependencies;
- project extras/targets;
- piracy where relevant;
- unbound arguments.

### JET

Analyse representative public calls. Treat definite runtime dispatch/errors in hot paths as failures. Suppress only understood false positives with comments.

### Formatting

Use `JuliaFormatter.jl` via a documented command. Formatting need not run in runtime dependencies.

### Coverage

Upload coverage if configured, but do not optimise for superficial line coverage. Require branch coverage conceptually for policy and solver status branches.

## CI additions

Add jobs:

- standard test matrix;
- threaded Linux test with at least 4 Julia threads;
- documentation build;
- Aqua/JET;
- optional nightly Julia allowed to fail initially;
- benchmark smoke test on small sizes, validating outputs but not enforcing timings.

Do not enforce wall-clock benchmark thresholds in shared GitHub-hosted CI.

## Performance reporting

`docs/src/performance.md` must report:

- hardware/OS/Julia version;
- package commit;
- thread count;
- input size and coordinate mode;
- diagnostic mode;
- minimum/median time and allocations;
- correctness tolerance used in comparisons.

Do not publish speedup ratios across unequal row counts or include setup in only one side.

## Acceptance criteria

- no type instability in core scalar path;
- no per-row heap container in preallocated batch;
- threaded mode has serial-equivalence tests;
- benchmark scripts are reproducible and save metadata;
- no unsubstantiated performance claims in README;
- package remains correct with bounds checks enabled.

## Suggested commit

`perf: validate and optimise Julia execution paths`
