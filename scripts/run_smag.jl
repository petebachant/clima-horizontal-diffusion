using Revise, JLD2, BenchmarkTools, ClimaAtmos
import ClimaAtmos as CA
import CUDA

@load "results/smag_fixture.jld2" Y Yt p t model

# Warmup once (JIT)
CA.horizontal_smagorinsky_lilly_tendency!(Yt, Y, p, t, model)

# Benchmark; reset Yt each run and sync if on GPU
Yt .= 0
@btime begin
    Yt .= 0
    CA.horizontal_smagorinsky_lilly_tendency!($Yt, $Y, $p, $t, $model)
    CUDA.synchronize()
end
