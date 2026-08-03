# Wind preprocessing API contract

Standalone wind, height, GHI, delta-T and optional floor inputs are finite real
scalars. Wind is nonnegative and heights are positive. Automatic stability
requires `daytime::Bool`; daytime rows require nonnegative GHI and nighttime
rows require vertical temperature difference. Explicit stability bypasses
those requirements.

High-level APIs derive daytime from solar zenith and use resolved GHI. Batch
height and delta-T follow the package's scalar/aligned numeric expansion;
terrain and stability accept shared values or aligned vectors. Preallocated
calls validate lengths, element types and aliases before writing outputs.
