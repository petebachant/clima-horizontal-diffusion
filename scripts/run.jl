#=
Run a simulation
=#
redirect_stderr(IOContext(stderr, :stacktrace_types_limited => Ref(false)))
import ClimaComms
ClimaComms.@import_required_backends
import Random
Random.seed!(1234)
import ClimaAtmos as CA
import CUDA
import SciMLBase: step!

redirect_stderr(IOContext(stderr, :stacktrace_types_limited => Ref(false)))
import YAML

"""
    TargetJobConfig(target_job)

Creates a full model configuration from the given target job.
"""
TargetJobConfig(target_job) =
    CA.AtmosConfig(CA.config_from_target_job(target_job))

import ClimaTimeSteppers as CTS
get_W(i::CTS.DistributedODEIntegrator) =
    hasproperty(i.cache, :W) ? i.cache.W : i.cache.newtons_method_cache.j
get_W(i::CTS.RosenbrockAlgorithm) = i.cache.W
get_W(i) = i.cache.W
f_args(i, f::CTS.ForwardEulerODEFunction) = (copy(i.u), i.u, i.p, i.t, i.dt)
f_args(i, f) = (similar(i.u), i.u, i.p, i.t)

r_args(i, f::CTS.ForwardEulerODEFunction) =
    (copy(i.u), copy(i.u), i.u, i.p, i.t, i.dt)
r_args(i, f) = (similar(i.u), similar(i.u), i.u, i.p, i.t)

implicit_args(i::CTS.DistributedODEIntegrator) = f_args(i, i.sol.prob.f.T_imp!)
implicit_args(i) = f_args(i, i.f.f1)
remaining_args(i::CTS.DistributedODEIntegrator) =
    r_args(i, i.sol.prob.f.T_exp_T_lim!)
remaining_args(i) = r_args(i, i.f.f2)
wfact_fun(i) = implicit_fun(i).Wfact
implicit_fun(i::CTS.DistributedODEIntegrator) = i.sol.prob.f.T_imp!
implicit_fun(i) = i.sol.prob.f.f1
remaining_fun(i::CTS.DistributedODEIntegrator) = i.sol.prob.f.T_exp_T_lim!
remaining_fun(i) = i.sol.prob.f.f2

project_dir = dirname(Base.active_project())
@info "Active project: $project_dir"

(; config_file, job_id) = CA.commandline_kwargs()
config = CA.AtmosConfig(config_file; job_id)

simulation = CA.get_simulation(config)
(; integrator) = simulation;
Y₀ = deepcopy(integrator.u);

# Step once to compile
step!(integrator)

n_steps = 2048

e = CUDA.@elapsed begin
    for n in 1:n_steps
        step!(integrator)
    end
end

@info "Ran step! $n_steps times in $e s, ($(CA.prettytime(e/n_steps*1e9)) per step)"
