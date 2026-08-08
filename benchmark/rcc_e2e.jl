# Reproducible RCC scalar/aligned-batch cost benchmark. Timings compare distinct
# algorithms as execution-cost context, never as equivalent implementations.
using BenchmarkTools
using Dates
using HeatStress

function rcc_inputs(rows::Int)
    rows > 0 || throw(ArgumentError("rows must be positive"))
    time = [DateTime(2025, 7, 1, 12) + Minute(mod(i - 1, 180)) for i in 1:rows]
    phase = range(0, 2π; length = rows + 1)[1:rows]
    air = 31 .+ 4 .* sin.(phase)
    humidity = 55 .+ 25 .* cos.(phase)
    wind = 0.25 .+ 3 .* abs.(sin.(phase))
    ghi = 650 .+ 250 .* abs.(cos.(phase))
    return (; air, humidity, wind, time, ghi)
end

function rccd_scalar(inputs)
    return [
        rccd167l_wbgt(
            inputs.air[i], inputs.humidity[i], inputs.wind[i], inputs.time[i],
            0.0, 0.0; ghi_w_m2 = inputs.ghi[i],
        ) for i in eachindex(inputs.air)
    ]
end

function rccd_batch(inputs)
    return rccd167l_wbgt_batch(
        inputs.air, inputs.humidity, inputs.wind, inputs.time, 0.0, 0.0;
        ghi_w_m2 = inputs.ghi,
    )
end

function rcc_nws_batch(inputs)
    return rcc_nws_wbgt_batch(
        inputs.air, inputs.humidity, inputs.wind, inputs.time, 0.0, 0.0;
        ghi_w_m2 = inputs.ghi,
    )
end

function liljegren_scalar(inputs)
    return [
        liljegren_wbgt(
            inputs.air[i],
            # A fixed dew-point depression supplies an ordinary Liljegren
            # workload; inputs are not intended as cross-model matched states.
            inputs.air[i] - 5.0,
            inputs.wind[i], inputs.time[i], 0.0, 0.0;
            ghi_w_m2 = inputs.ghi[i],
            partition = LiljegrenClearnessFraction(),
        ) for i in eachindex(inputs.air)
    ]
end

function main(args = ARGS)
    rows = isempty(args) ? 100_000 : parse(Int, first(args))
    samples = length(args) < 2 ? 5 : parse(Int, args[2])
    inputs = rcc_inputs(rows)
    reference = rccd_scalar(inputs)
    @assert rccd_batch(inputs).wbgt_c == getproperty.(reference, :wbgt_c)
    println("rows=$rows samples=$samples")
    for (name, operation) in (
        ("RCCD167L scalar", rccd_scalar),
        ("RCCD167L aligned batch", rccd_batch),
        ("RCC/NWS aligned batch", rcc_nws_batch),
        ("Liljegren scalar context", liljegren_scalar),
    )
        trial = @benchmark $operation($inputs) samples = samples evals = 1
        estimate = BenchmarkTools.median(trial)
        println(name, ": ", estimate.time / 1e9, " s; ", estimate.memory,
                " bytes; ", estimate.allocs, " allocations")
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
