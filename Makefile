# Environment directories
BASE_DIR=resources/terraform
MODULE_DIR=terraform/modules

# Path for files and backend
BACKEND_CONFIG="./backend.config"

# Available envs
ENVS=dev staging prod

# Default Terraform command with directory
TERRAFORM=terraform -chdir=$(BASE_DIR)

# ----------------------------
# Main commands
# ----------------------------

init:
	@echo "🔧 Initializing backend for environment '$(STAGE)'..."
	rm -rf $(BASE_DIR)/.terraform
	$(TERRAFORM) init \
							 -backend-config="resource_group_name=tf-state-rg" \
               -backend-config="storage_account_name=$(BACKEND_STORAGE_ACCOUNT)" \
               -backend-config="container_name=tfstate" \
               -backend-config="key=$(REPOSITORY_NAME).$(STAGE).tfstate" \

plan:
	@echo "🔍 Generating plan for environment '$(STAGE)'..."
	$(TERRAFORM) plan -var "stage=$(STAGE)"

apply:
	@echo "🚀 Applying infrastructure in environment '$(STAGE)'..."
	$(TERRAFORM) apply -var "stage=$(STAGE)" -auto-approve

deploy: apply
# deploy: init apply

destroy:
	@echo "🔥 Destroying infrastructure in environment '$(STAGE)'..."
	$(TERRAFORM) destroy -var "stage=$(STAGE)" -auto-approve

# ----------------------------
# Help
# ----------------------------

help:
	@echo "💡 Available commands:"
	@echo "  make init env=dev       - Initializes the backend"
	@echo "  make plan env=dev       - Generates Terraform plan"
	@echo "  make apply env=dev      - Applies the changes"
	@echo "  make deploy env=dev     - Initializes the backend and applies the changes"
	@echo "  make destroy env=dev    - Destroys the infrastructure"
	@echo ""
	@echo "🌍 Available environments: $(ENVS)"