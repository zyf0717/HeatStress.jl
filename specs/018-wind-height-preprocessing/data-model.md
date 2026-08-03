# Wind-height preprocessing data model

`WindHeightDiagnostics{T}` stores the promoted supplied wind and heights,
reference-height wind before the floor, effective wind after the floor,
nullable stability class/exponent, explicit-class provenance, and boolean
height/floor application flags.

`WindHeightDiagnosticsBatch{T}` stores an aligned vector for each scalar field.
It is nested in `DiagnosticWBGTBatchResult`, matching the existing irradiance
and solver diagnostic structure-of-arrays design.

`vertical_temperature_difference_c` remains row meteorology. It is not a
field of `LiljegrenConfig`.
