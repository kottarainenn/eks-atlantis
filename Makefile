SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

.PHONY: up down check bootstrap infra atlantis verify demo-destroy atlantis-destroy infra-destroy bootstrap-destroy

up: check bootstrap infra atlantis verify

down: check demo-destroy atlantis-destroy infra-destroy bootstrap-destroy

check:
	@echo "Checking required tools and environment variables..."
	@command -v terraform >/dev/null || (echo "terraform not found"; exit 1)
	@command -v aws >/dev/null || (echo "aws CLI not found"; exit 1)
	@command -v kubectl >/dev/null || (echo "kubectl not found"; exit 1)
	@command -v helm >/dev/null || (echo "helm not found"; exit 1)
	@[ -n "$$AWS_PROFILE" ] || (echo "AWS_PROFILE is not set  - run source .env"; exit 1)
	@[ -n "$$TF_VAR_github_token" ] || (echo "TF_VAR_github_token is not set  - run source .env"; exit 1)
	@[ -n "$$TF_VAR_github_webhook_secret" ] || (echo "TF_VAR_github_webhook_secret is not set  - run source .env"; exit 1)
	@echo "All checks passed."

bootstrap:
	@echo "Applying bootstrap stack (S3 state bucket)..."
	cd terraform/0-bootstrap && terraform init -input=false && terraform apply -auto-approve
	@echo "bucket = \"$$(cd terraform/0-bootstrap && terraform output -raw bucket_name)\"" > terraform/1-infra/backend.hcl
	@echo "bucket = \"$$(cd terraform/0-bootstrap && terraform output -raw bucket_name)\"" > terraform/2-atlantis/backend.hcl
	@echo "bucket = \"$$(cd terraform/0-bootstrap && terraform output -raw bucket_name)\"" > demo/backend.hcl

infra:
	@echo "Applying infra stack (VPC, EKS, IAM roles)..."
	cd terraform/1-infra && terraform init -input=false -backend-config=backend.hcl && terraform apply -auto-approve
	aws eks update-kubeconfig --name luminor-eks --region eu-north-1

atlantis:
	@echo "Applying atlantis stack (Helm release, webhook)..."
	cd terraform/2-atlantis && terraform init -input=false -backend-config=backend.hcl && terraform apply -auto-approve

verify:
	@echo "Running access verification..."
	./scripts/verify-access.sh
	@echo "Checking Atlantis health endpoint..."
	curl -sf "http://$$(kubectl -n atlantis get svc atlantis -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/healthz" && echo "Atlantis is healthy."

demo-destroy:
	@echo "Destroying demo resources..."
	-cd demo && terraform init -input=false -backend-config=backend.hcl && terraform destroy -auto-approve

atlantis-destroy:
	@echo "Destroying atlantis stack..."
	-cd terraform/2-atlantis && terraform init -input=false -backend-config=backend.hcl && terraform destroy -auto-approve

infra-destroy:
	@echo "Destroying infra stack..."
	-cd terraform/1-infra && terraform init -input=false -backend-config=backend.hcl && terraform destroy -auto-approve

bootstrap-destroy:
	@echo "Destroying bootstrap stack..."
	-cd terraform/0-bootstrap && terraform destroy -auto-approve