# Public API contract

Implement and export names only when their associated specification is complete. The canonical Liljegren scalar call accepts air temperature, dew point, wind speed, solar radiation, time, longitude and latitude; pressure, direct fraction and `LiljegrenConfig` are keywords.

Value-only calls return `WBGTResult`; diagnostic calls return `DiagnosticWBGTResult`. A diagnostics Boolean must not change return shape. `DateTime` is UTC, `ZonedDateTime` is converted to its UTC instant, and `Missing` time/input follows the documented unattempted-result semantics.

See `spec.md` for the definitive signatures, enums, result fields and missingness contract.
