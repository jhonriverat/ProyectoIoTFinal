.PHONY: aws-up aws-down local-up local-down logs api-build api-push api-deploy clean

REGION     = us-east-1
ACCOUNT_ID = $(shell aws sts get-caller-identity --query Account --output text)
ECR_REPO   = $(shell cd terraform && terraform output -raw ecr_repository_url 2>/dev/null)

# ==========================================
# AWS (Terraform)
# ==========================================

# Primero solo ECR, luego build/push, luego todo
aws-up:
	@echo "Desplegando infraestructura en AWS..."
	mkdir -p edge_gateway/certs
	@echo "Empaquetando Lambda..."
	bash build_lambda.sh
	cd terraform && terraform init && terraform apply -target=module.compute.aws_ecr_repository.api_repo -auto-approve
	$(MAKE) api-push
	cd terraform && terraform apply -auto-approve
	@echo ""
	@echo "=== Despliegue completo ==="
	@cd terraform && terraform output api_url

aws-down:
	@echo "Destruyendo infraestructura en AWS..."
	cd terraform && terraform destroy -auto-approve
	@echo "Infraestructura de AWS destruida."

# ==========================================
# Local (Docker Compose)
# ==========================================
local-up:
	@echo "Levantando Edge Gateway (Mosquitto) y Sensores locales..."
	docker compose up -d --build
	@echo "Contenedores iniciados. Usa 'make logs' para ver el flujo de datos."

local-down:
	@echo "Deteniendo contenedores locales..."
	docker compose down
	@echo "Contenedores detenidos."

logs:
	docker compose logs -f

# ==========================================
# API (Docker + ECR + ECS)
# ==========================================
api-build:
	@echo "Construyendo imagen Docker de la API (linux/amd64 para ECS)..."
	cd api && docker buildx build --platform linux/amd64 -t iot-api .
	docker tag iot-api:latest $(ECR_REPO):latest

api-push: api-build
	@echo "Subiendo imagen a ECR..."
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ECR_REPO)
	docker push $(ECR_REPO):latest
	@echo "Imagen subida."

api-deploy: api-push
	@echo "Forzando re-deploy del servicio ECS..."
	aws ecs update-service \
		--cluster $(shell cd terraform && terraform output -raw ecs_cluster_name 2>/dev/null) \
		--service $(shell cd terraform && terraform output -raw ecs_service_name 2>/dev/null) \
		--force-new-deployment \
		--region $(REGION) > /dev/null
	@echo "API disponible en:"
	@cd terraform && terraform output api_url

# ==========================================
# Limpieza
# ==========================================
clean: local-down aws-down
	@echo "Limpiando certificados locales..."
	rm -rf edge_gateway/certs/*
	rm -f edge_gateway/mosquitto.conf
	rm -rf terraform/.terraform terraform/.terraform.lock.hcl terraform/terraform.tfstate terraform/terraform.tfstate.backup
	@echo "Limpiando Lambda..."
	rm -rf lambdas/s3_to_postgres/package
	rm -f lambdas/s3_to_postgres/lambda.zip
	@echo "Entorno limpio."
