#!/bin/bash
#SBATCH --gpus=1

# First command line argument is the project directory
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <project_dir> <script_path> [additional_args...]"
  exit 1
fi
PROJECT_DIR=$1
shift

# Parse script path
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <project_dir> <script_path> [additional_args...]"
  exit 1
fi
SCRIPT_PATH=$1
shift

# Load modules
module purge
module load climacommon/2025_05_15

# Set environment variables for GPU usage
export CLIMACOMMS_DEVICE=CUDA
export CLIMA_NAME_CUDA_KERNELS_FROM_STACK_TRACE=true

# Set environmental variable for julia to not use global packages for
# reproducibility
export JULIA_LOAD_PATH=@:@stdlib

# Instantiate julia environment, precompile, and build CUDA
julia --project=$PROJECT_DIR -e 'using Pkg; Pkg.instantiate(;verbose=true); Pkg.precompile(;strict=true); using CUDA; CUDA.precompile_runtime(); Pkg.status()'

# Simply pass through whatever arguments are given to this script
julia --project=$PROJECT_DIR \
    $SCRIPT_PATH \
    "$@"
