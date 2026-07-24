module HeatStress

using Dates
using TimeZones

include("constants.jl")
include("types.jl")
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
include("liljegren/scalar.jl")
include("liljegren/batch.jl")
include("indices/stull.jl")
include("indices/bernard.jl")
include("indices/simplified_wbgt.jl")
include("indices/apparent_temperature.jl")
include("indices/effective_temperature.jl")
include("indices/humidex.jl")
include("indices/discomfort_index.jl")
include("indices/heat_index.jl")

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
    WBGTBatchResult

end
