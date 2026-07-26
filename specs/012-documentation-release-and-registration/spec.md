# Documentation and release readiness

## Purpose

Prepare a focused, scientifically transparent MIT-licensed Liljegren-first
`v0.1.0` for final audit and Julia General registration. This unit establishes
readiness; it does not tag, publish or register the package.

## Scheduling

This is the immediate delivery milestone after the remaining Liljegren/core
validation slice of 010 and publication gate of 011. It depends on the
completed core implementation through 008 and the completed readability
refactor 014. It does **not** depend on spec 009, secondary-index fixtures, a
complete HeatStressR comparison, or deeper optimisation.

The release is deliberately focused: solar geometry and model-required
psychrometric helpers; Liljegren globe, natural wet-bulb and WBGT calculations;
diagnostic APIs; and serial, preallocated and threaded batch APIs. Stull,
Bernard, humidex, heat index and other secondary indices are post-v0.1 work.

## README and documentation

The README must cover package status/scope, installation, minimal scalar and
batch/threading examples, returned result/diagnostic fields, units/timestamp
semantics, provenance, validation, numerical failures, limitations, MIT
licence and citation. Do not claim equivalence to all Liljegren implementations:
pressure, wind treatment, timestamp convention, solar method, radiation
partitioning, instrument parameters and numerical policies must match. Do not
claim a HeatStressR speed ratio without a reproducible, correctness-gated
committed report.

The documentation must provide:

- `index.md`: focused scope and quick start;
- `api.md`: released public signatures and result types;
- `liljegren.md`: conceptual equations, source citations, component solving,
  WBGT composition and configurable physical parameters;
- `inputs.md`: units, timestamp semantics, policies and radiation inputs;
- `numerical-behaviour.md`: bracketing, tolerances, failures, missingness and
  diagnostics;
- `performance.md`: host-specific Julia baseline, explicitly not a universal
  guarantee or cross-language ratio;
- `provenance.md`: independent-literature implementation statement, primary
  sources and honest advisory HeatStressR familiarity disclosure.

Examples must be executable and small, including scalar, zoned-time and batch
calls. Plain `DateTime` is documented as UTC.

## Release-wide quality and registration readiness

Routine pull-request CI has exactly three checks: minimum Julia 1.10 with four
threads on Linux, current Julia on Linux with Aqua, JET and documentation, and
current Julia on Windows. Cancel superseded runs for the same pull request.
Do not run macOS, benchmark or clean-depot jobs in routine CI. Retain
clean-depot testing and output-validating benchmark smoke commands for manual
release-readiness validation; do not enforce wall-clock thresholds on shared
runners. Audit exports and `[compat]`, and recheck package-name availability.

Use standard MIT licence text, identify holder/year, include citation and
contribution provenance guidance, and add no third-party source without a
recorded compatible licence. Validate Registrator, TagBot and the intended
archival workflow without publishing.

## Release-readiness checklist

1. complete the declared v0.1 release scope: core 000–008 evidence, the
   Liljegren/core slice of 010, publication gate of 011 and 014;
2. set candidate version to `0.1.0`;
3. make README, examples, API documentation, units/timestamp semantics,
   numerical-failure explanation, provenance and limitations accurate;
4. audit MIT/citation/contribution material, licences, exports and `[compat]`;
5. run the three routine CI checks: Linux Julia 1.10 with four threads, Linux
   current Julia with Aqua, JET and warning-free docs, and Windows current
   Julia; run clean-depot installation/test separately for release readiness;
6. record scoped scientific validation and host-specific benchmark evidence;
7. recheck package-name conflict and validate Registrator, TagBot and archival
   setup without publication;
8. freeze the candidate tree and define the handoff that passes its post-commit
   SHA to spec 013.

Do not require spec 009, its fixture families, or Tier 2 of spec 011. Tagging,
GitHub release creation, archival and General registration are post-audit
actions governed by spec 013.

## Acceptance criteria

- all declared v0.1 APIs have executable examples, docstrings and appropriate
  scientific citations;
- docs explain numerical failure rather than hiding it;
- provenance accurately describes prior HeatStressR familiarity without
  presenting HeatStressR as the source;
- release material describes an independent MIT Liljegren-first implementation,
  not a port or all-index package;
- routine CI covers minimum Julia, threading, current Julia, Windows, Aqua,
  JET and documentation; clean-depot, export and registration readiness checks
  pass separately for the focused release surface;
- no tag, archive, registry submission or other public release action occurs
  before spec 013 authorises the candidate commit.

## Suggested commit

`docs: prepare Liljegren-first v0.1.0 for audit`
