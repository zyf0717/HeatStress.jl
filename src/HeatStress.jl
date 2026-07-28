module HeatStress

using Dates
using TimeZones

include("constants.jl")
include("types/statuses.jl")
include("types/configuration.jl")
include("types/results.jl")
include("types/diagnostics.jl")
include("policies.jl")
include("validation.jl")
include("psychrometrics.jl")
include("solar_geometry.jl")
include("heat_transfer.jl")
include("liljegren/residuals.jl")
include("liljegren/root_solver.jl")
include("liljegren/diagnostics.jl")
include("liljegren/globe_temperature.jl")
include("liljegren/natural_wet_bulb.jl")
include("liljegren/scalar_types.jl")
include("liljegren/balance_construction.jl")
include("liljegren/result_materialisation.jl")
include("liljegren/row_execution.jl")
include("liljegren/api.jl")
include("liljegren/batch.jl")

# Public exports are declared here once their owning specifications are complete.
export DewPointPolicy,
    ClampDewPoint,
    SwapAirAndDewPoint,
    RejectInvalidDewPoint,
    InputStatus,
    InputAccepted,
    MissingMeteorology,
    MissingTime,
    InvalidDewPoint,
    InvalidDomain,
    FailureReason,
    NoFailure,
    NotAttempted,
    Unbracketed,
    NonFiniteResidual,
    ResidualValidationFailed,
    IterationLimit,
    SolverConfig,
    LiljegrenConfig,
    WBGTResult,
    SolverDiagnostics,
    DiagnosticWBGTResult,
    WBGTBatchResult,
    SolverDiagnosticsBatch,
    DiagnosticWBGTBatchResult,
    globe_temperature,
    natural_wet_bulb_temperature,
    liljegren_wbgt,
    diagnose_liljegren,
    liljegren_wbgt_batch,
    liljegren_wbgt!,
    diagnose_liljegren_batch,
    solar_zenith,
    solar_zenith_batch,
    saturation_vapour_pressure_hpa,
    vapour_pressure,
    relative_humidity_from_dewpoint

end
