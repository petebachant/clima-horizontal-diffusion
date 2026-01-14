import JLD2
import ClimaCore.Fields as Fields
using Statistics
using CairoMakie

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
    local max_diff = maximum(abs.(diff))
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

# Compute comprehensive difference metrics
abs_diff = abs.(diff)
finite_mask = isfinite.(abs_diff)

if sum(finite_mask) > 0
    finite_diff = diff[finite_mask]
    finite_abs_diff = abs_diff[finite_mask]

    # Mean difference
    mean_diff = mean(finite_diff)
    @info "Mean difference: $mean_diff"

    # Mean absolute error
    mae = mean(finite_abs_diff)
    @info "Mean absolute error: $mae"

    # Root mean square error
    rmse = sqrt(mean(finite_diff .^ 2))
    @info "RMSE: $rmse"

    # Additional useful statistics
    median_abs_diff = median(finite_abs_diff)
    @info "Median absolute difference: $median_abs_diff"

    std_diff = std(finite_diff)
    @info "Std dev of difference: $std_diff"

    # Find location of maximum absolute difference
    max_abs_diff, max_idx = findmax(abs_diff)
    @info "Maximum absolute difference location:"
    @info "  Value: $max_abs_diff"
    @info "  Indices: $max_idx"
    @info "  Baseline value at max: $(uh_baseline[max_idx])"
    @info "  Modified value at max: $(uh_mod[max_idx])"
    @info "  Difference at max: $(diff[max_idx])"

    # If array is 5D, provide dimension labels
    if ndims(diff) == 5
        idx_tuple = Tuple(max_idx)
        @info "  Dimension breakdown: z=$(idx_tuple[1]), x=$(idx_tuple[2]), y=$(idx_tuple[3]), component=$(idx_tuple[4]), time=$(idx_tuple[5])"
    end
else
    @info "No finite differences found for statistics"
end

# Generate visualizations
if sum(finite_mask) > 0
    # Create a figure with multiple plots
    fig = Figure(size=(1400, 900))

    # Histogram of differences
    ax1 = Axis(fig[1, 1], xlabel="Difference", ylabel="Frequency", title="Distribution of differences")
    hist!(ax1, finite_diff, bins=50, color=:blue, alpha=0.7)

    # Histogram of absolute differences
    ax2 = Axis(fig[1, 2], xlabel="Absolute difference", ylabel="Frequency", title="Distribution of absolute differences")
    hist!(ax2, finite_abs_diff, bins=50, color=:red, alpha=0.7)

    # Heatmap of differences if 2D or higher dimensional
    if ndims(diff) >= 2
        ax3 = Axis(fig[2, :], xlabel="X", ylabel="Y", title="Difference field heatmap (first 2-D slice)")
        if ndims(diff) == 2
            hm = heatmap!(ax3, diff)
        elseif ndims(diff) == 3
            hm = heatmap!(ax3, diff[:, :, 1])
        elseif ndims(diff) == 4
            hm = heatmap!(ax3, diff[:, :, 1, 1])
        elseif ndims(diff) == 5
            hm = heatmap!(ax3, diff[:, :, 1, 1, 1])
        else
            # For higher dimensions, take first slice of all but first 2 dims
            hm = heatmap!(ax3, diff[:, :, 1, 1, 1, 1])
        end
        Colorbar(fig[2, end+1], hm, label="Difference")
    end
    mkpath("figures")
    save("figures/smag-uh-diff.png", fig)
    @info "Saved difference analysis to figures/smag-uh-diff.png"
end
