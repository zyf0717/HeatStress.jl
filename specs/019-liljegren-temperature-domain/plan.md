# Liljegren temperature-domain correction: implementation plan

1. Replace the high-level Celsius interval with post-policy positive-Kelvin
   validation.
2. Validate primitive transport properties before constructing the
   mass-transfer coefficient, then reject non-finite or non-positive derived
   state before component solving.
3. Add boundary, policy, solver-attempt and derived-state regressions.
4. Update input and provenance documentation without broadening the public
   psychrometric API.
5. Run focused tests followed by `Pkg.test()` and record the evidence.
