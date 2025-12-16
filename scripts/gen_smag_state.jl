#=
This script generates an initial atmospheric state for testing and
benchmarking purposes.
=#

ENV["CLIMACOMMS_DEVICE"] = "CUDA"
ENV["CLIMA_NAME_KERNELS_FROM_STACK_TRACE"] = "true"

redirect_stderr(IOContext(stderr, :stacktrace_types_limited => Ref(false)))
import ClimaComms
ClimaComms.@import_required_backends
import Random
Random.seed!(1234)
import ClimaAtmos as CA
import CUDA
import JLD2

append!(
    ARGS,
    [
        "--config_file",
        "config/base.yml",
        "--config_file",
        "config/smag.yml",
        "--job_id",
        "smag_fixture",
    ]
)

include("../ClimaAtmos.jl/perf/common.jl")
(; config_file, job_id) = CA.commandline_kwargs()
config = CA.AtmosConfig(config_file; job_id)

simulation = CA.get_simulation(config)
(; integrator) = simulation;

# Snapshot the current state/params/time
Y = deepcopy(integrator.u)
Yt = deepcopy(integrator.u)
Yt .= 0
p = integrator.p
t = integrator.t

# Resolve the Smagorinsky–Lilly model from the cached atmos physics
model = p.atmos.smagorinsky_lilly
@assert model isa CA.SmagorinskyLilly "Could not find SmagorinskyLilly model; adjust the lookup above."

# Ensure precomputes are ready in the snapshot
CA.set_smagorinsky_lilly_precomputed_quantities!(Y, p, model)

# Serialize for fast REPL iteration
savepath = joinpath(pwd(), "results", "smag_fixture.jld2")
mkpath(dirname(savepath))
JLD2.@save savepath Y Yt p t model
@info "Saved Smagorinsky fixture → $savepath"
