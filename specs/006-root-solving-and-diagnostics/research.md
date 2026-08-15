# Root solving and diagnostics: research

## Required sources

- Numerical root-finding literature selected in `spec.md`.
- Liljegren component residual requirements.

The authoritative detail and citations remain in `spec.md`; software implementations are not scientific authorities.

## Findings to record

- Equation, coefficient, policy or design decision.
- Source identifier, section/equation and units.
- Independent validation method and tolerance.

## Findings and decisions

- The globe location residual is `Tg^4 - equilibrium_radicand(Tg)` (K⁴), as
  recorded in spec 005. Existing independent fixture signs are negative at
  320 K and positive at 325 K. The fourth-power emission term and convective
  loss make it increase through ordinary roots, so same-positive brackets
  expand downward and same-negative brackets expand upward. Each globe step is
  the current bracket width, bounded by air temperature ±200 K.
- The natural-wet-bulb residual is candidate minus equilibrium temperature
  (K), with independent fixture signs negative at 295 K and positive at 300
  K. The selected lower/upper starts are dew point −1 K and air temperature
  +1 K, clipped to the `233.15--323.15 K` Buck domain. Both endpoints move
  outward by at most 10 K per recovery cycle; this does not presume a
  particular initial sign direction or extrapolate the psychrometric equation.
- `SolverConfig` defaults were already specified in unit 002. A 400 K globe
  bracket needs at most 29 bisections for a 1e-6 K Float64 bracket, far below
  the 128 iteration cap. Float32 cannot always represent a 1e-6 K bracket near
  ambient temperatures, so adjacent representable endpoints are a successful
  location stop; their recorded width makes the precision limit visible.
- Bisection was selected over interpolation for deterministic bracket and
  evaluation diagnostics. No fallback solver is used.

## Validation method

- Generic tests cover linear/nonlinear roots, endpoint roots, both expansion
  policies, unbracketed and non-finite exits, iteration cap, deterministic
  diagnostics, independent residual validation, Float32 and Float64.
- Component tests use the independently constructed physical-kernel globe and
  wet-bulb balances, plus a high-forcing globe balance that remains
  unbracketed within its documented search guardrail.
