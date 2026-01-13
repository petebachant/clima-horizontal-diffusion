import JLD2
import ClimaCore.Fields as Fields

uh_baseline = JLD2.load("results/uh_debug_baseline_smag.jld2")["uh"]
uh_mod = JLD2.load("results/uh_debug_mod_smag.jld2")["uh"]

uh_baseline = parent(uh_baseline)
uh_mod = parent(uh_mod)

# Check for NaNs
n_nan_baseline = sum(isnan.(uh_baseline))
n_nan_mod = sum(isnan.(uh_mod))
@info "NaNs in baseline: $n_nan_baseline, NaNs in mod: $n_nan_mod"

# Count finite values
n_finite_baseline = sum(isfinite.(uh_baseline))
n_finite_mod = sum(isfinite.(uh_mod))
@info "Finite values in baseline: $n_finite_baseline, Finite values in mod: $n_finite_mod"

# Compare only finite values
diff = uh_baseline .- uh_mod
finite_mask = isfinite.(diff)
if sum(finite_mask) > 0
    max_diff = maximum(abs.(diff[finite_mask]))
    @info "Maximum difference (finite values only): $max_diff"
else
    @info "No finite differences found"
end

@info "Baseline shape: $(size(uh_baseline))"
@info "Mod shape: $(size(uh_mod))"

# Compute difference
diff = uh_baseline .- uh_mod

# Try to get max of absolute value
try
    max_diff = maximum(abs.(diff))
    @info "Maximum difference: $max_diff"

    if isnan(max_diff)
        @info "max_diff is NaN - checking if diff field is all zeros or has issues"
        @info "First few values of diff: $(diff[1:min(5, length(diff))])"
    elseif max_diff < 1e-10
        @info "Fields are essentially identical"
    else
        @info "Fields differ by: $max_diff"
    end
catch e
    @info "Error: $e"
    @info "Diff field: $diff"
end
