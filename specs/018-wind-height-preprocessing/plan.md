# Wind-height preprocessing: implementation plan

1. Add public wind policy, terrain, stability and diagnostic types.
2. Implement and independently test the SRDT classifier, exponent lookup and
   power-law conversion.
3. Insert adjustment between meteorological normalization and component
   balances, preserving the no-op path.
4. Extend scalar and batch contracts, diagnostics and validation.
5. Update documentation, provenance and acceptance evidence.
