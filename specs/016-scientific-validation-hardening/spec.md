# Scientific validation hardening

## Purpose

Strengthen evidence that HeatStress.jl faithfully and numerically stably
implements its selected published equations and documented policies. This unit
validates numerical conformance; it does not assess empirical model accuracy,
field performance, exposure guidance or clinical suitability.

Specs 010, 013 and 015 remain historical release records. Spec 022 authorizes
replacement of current Liljegren expectations in the stable v1/v3 fixture
paths; Git history preserves the earlier release evidence. The secondary-only
v2 family is unchanged.

## Compatibility

- Do not change exports, public method signatures, default configuration,
  accepted input domains, clamping policies or runtime dependencies.
- Preserve public interfaces; scientific corrections may change numerical
  results and missingness when their provenance and sensitivity are recorded.
- Do not tag, publish, register or otherwise release under this unit.

## Fixture set v3

Maintain the offline `fixture-set-v3` with:

- exactly 64 end-to-end Liljegren reference scenarios;
- component roots, brackets, validation residuals and expected statuses;
- public input failures and synthetic solver coverage for every
  `FailureReason`;
- expanded solar, psychrometric, physical-kernel and secondary-index evidence.

The 64 Liljegren scenarios use pairwise coverage across seven four-level
factors:

| Factor | Levels |
| --- | --- |
| air temperature (°C) | `-30`, `0`, `25`, `50` |
| dew-point state | saturated, 2 °C depression, 10 °C depression, `-40 °C` |
| wind (m/s) | `0`, `0.13`, `1`, `10` |
| radiation (W/m²) | `0`, `200`, `800`, `1200` |
| pressure (hPa) | `700`, `850`, `1010`, `1100` |
| direct fraction | `0`, `0.33`, `0.67`, `1` |
| geometry | equatorial noon/night, mid-latitude low sun, high-latitude summer |

Enumerate the full Cartesian candidate set. Repeatedly choose the candidate
covering the most uncovered factor-level pairs, breaking ties by the
lexicographic factor-index tuple. After pairwise coverage is complete, fill to
64 rows by maximizing newly covered three-factor level tuples with the same
tie-break. A test must independently verify pairwise coverage and row count.

## Independent generation

The v3 generator:

- runs at 256-bit `BigFloat` precision;
- imports neither `HeatStress` nor repository `src/`;
- keeps case inputs separate from generated expectations;
- recomputes expectations in memory in `--check` mode and byte-compares them
  with committed fixtures;
- records schema/generator versions, precision, timezone, row counts and
  SHA-256 output digests;
- uses only source identifiers registered in `validation/sources.toml`.

Expected values must not be modified to fit production output. A disagreement
is resolved by reviewing the publication, standalone calculation and Julia
implementation, then fixing the defective artifact with a regression case.

## Validation semantics

- Apply absolute/relative tolerances per row, never by family maximum.
- Compare statuses and missingness exactly.
- Accepted component candidates must be finite, lie in the final bracket and
  satisfy the configured validation-residual tolerance.
- Complete WBGT requires both components; a valid single component is retained.
- Scalar, allocating batch, preallocated batch, diagnostic, serial and threaded
  paths must agree.
- Float32 must preserve status/missingness and agree with Float64 within
  `2e-3 °C`, except for an explicitly documented representability case.
- Failure reports include family, fixture ID, authority, source, all inputs,
  expected/actual status and value, absolute error and permitted tolerance.

## Deterministic property suite

Generate 256 accepted-domain observations with a Halton sequence using bases
`2, 3, 5, 7, 11, 13, 17`. Verify:

- scalar/batch/thread/preallocated equivalence and permutation invariance;
- diagnostic/value consistency and WBGT recomposition;
- every returned numeric value is finite and every failure is `missing`;
- accepted roots satisfy bracket and residual invariants;
- default and tighter solvers agree within `5e-4 °C` when both accept.

Do not assert empirical accuracy or unsupported physical monotonicity.

## CI and reporting

- Run standalone v3 recomputation and the full suite for every pull request.
- Retain minimum-Julia threaded, current-Julia quality/docs and Windows jobs;
  add current-Julia macOS and `main` push validation.
- Produce an LCOV artifact on current Linux without a percentage gate.
- Resolve local environments so tests run without a stale-manifest warning;
  do not begin tracking manifests excluded by repository policy.

## Acceptance criteria

- current Liljegren v1/v3 expectations and metadata identify the spec-022
  equation revision while Git preserves prior audit evidence;
- the v3 generator is deterministic, standalone and reproducible;
- all v3 schema, coverage, numerical, failure and property checks pass;
- focused, full, four-thread, Aqua, JET and documentation checks pass;
- CI contains the recomputation, coverage artifact, macOS and main-push gates;
- `tasks.md` records commands, assertion counts and known deviations.
