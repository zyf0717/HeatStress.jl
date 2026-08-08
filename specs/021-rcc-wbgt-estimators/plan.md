# RCC WBGT estimators: implementation plan

1. Audit WP-25-001, its Appendix B procedure, Dimiceli and Piltz, and the NDFD
   design note; register every selected equation and policy before runtime code.
2. Implement type-stable psychrometric, natural-wet-bulb and globe kernels in
   an isolated `src/rcc/` model directory.
3. Generate deterministic independent fixtures without importing HeatStress;
   add component and scalar composition tests.
4. Add named scalar APIs and a shared typed RCC row engine using existing solar
   geometry and partition functions.
5. Add aligned allocating/preallocated batch APIs with complete pre-mutation
   shape, storage and alias validation.
6. Update result documentation, public docs, provenance and benchmarks; run
   focused, full and quality validation before recording completion evidence.
