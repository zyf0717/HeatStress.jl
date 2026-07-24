# v0.1.0 Liljegren scientific-validation report

- Audited source candidate: `eb7367d70d6a9a2b584c827d8cc30d50903001f8`
- Release surface: solar geometry and psychrometric helpers; Liljegren globe,
  natural wet-bulb, scalar/value/diagnostic and serial/preallocated/threaded
  batch APIs.
- Fixture set: `liljegren-core-v1`, schema 1, deterministic generator revision
  `v1`, 256-bit scalar reference authority, UTC, seed 0.
- Scope exclusion: secondary indices and cross-implementation comparisons are
  not v0.1 release conditions.

## Fixture results

| Family | Rows | Authority | Result |
| --- | ---: | --- | --- |
| Solar geometry | 5 | NREL SPA published examples | Maximum selected-method difference 0.240019° (leap-day equator), below the documented 2.0° selected-method allowance. |
| Psychrometrics | 3 | Analytic FAO-56 identities | All saturation/actual-vapour-pressure and saturated-RH identities pass. |
| Physical kernels | 3 | Independent direct equation evaluations | All viscosity, conductivity and diffusivity rows pass at `rtol=2e-14`. |
| Liljegren references | 4 | Standalone 256-bit calculation | 12 component/WBGT comparisons pass; maximum error `3.32935e-7 °C` (night globe), 95th percentile `3.17677e-7 °C`, below `1e-4 °C`. |
| Failure classifications | 3 | Contract invariants | Missing input, invalid pressure and partial-unbracketed classifications match exactly. |

`test/test_scientific_validation.jl` also verifies accepted residuals against
the configured tolerance, component retention, Float32 convergence, and
scalar/fixed/grouped/unique-coordinate batch equivalence including threaded
diagnostics. It passed 62 assertions on Julia 1.10.11.

## Invariants and quality evidence

- Accepted roots satisfy their independent Kelvin residual tolerances.
- WBGT is only present when both accepted components are present; partial
  component retention is tested.
- Batch output order, missingness, statuses and diagnostics agree with scalar
  execution for the exercised coordinate modes.
- The local quality suite (Aqua and JET), documentation build, benchmark output
  smoke, and clean-depot instantiate/precompile were run for this candidate.
- Candidate benchmark smoke on `znver3`, Julia 1.10.11, four threads preserved
  output equality; performance statements remain host-specific and contain no
  cross-language claim.

## Provenance and independence

`validation/sources.toml` maps every released formula family and fixture family
to literature or an explicit original-design rationale. Repository scans found
no runtime/test dependency on R, HeatStressR, Argonne code, GPL-derived source,
private comparison path, or committed binary. Mentions of HeatStressR/Argonne
are limited to policy/provenance disclosures and explicitly non-normative
comparison statements.

## Release decision

This is an evidence record, not release authorization. The candidate remains
blocked on completion of the pull-request platform checks and an explicit
maintainer scientific sign-off naming the audited source commit. Any later
audit-record-only commit must be diff-checked against this candidate before
tagging, release creation, archival, or General registration.
