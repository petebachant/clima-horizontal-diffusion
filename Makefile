.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)


.PHONY: srun-jupyter
srun-jupyter: ## Start an IJulia kernel for the notebook as a SLURM job
	srun --time=120 --gpus=1 --mpi=none --pty calkit jupyter lab --ip=0.0.0.0 --no-browser


.PHONY: install-calkit
install-calkit: ## Ensure Calkit and uv are installed
	@curl -LsSf https://github.com/calkit/calkit/raw/refs/heads/main/scripts/install.sh | sh
