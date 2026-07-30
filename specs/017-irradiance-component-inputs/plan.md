# Irradiance component inputs: implementation plan

1. Add public partition-policy and irradiance-diagnostic types.
2. Implement a pure irradiance resolver after solar geometry and before the
   existing Liljegren balances.
3. Replace scalar and batch signatures and migrate internal/fixture call sites.
4. Add all-combination, diagnostic and independent numerical validation.
5. Update public documentation and record full quality evidence.

The physical globe/wick equations and root solver are not changed.
