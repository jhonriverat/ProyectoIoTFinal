terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ==========================================

# Networking

# ==========================================

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================

# Storage (S3)

# ==========================================

module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================

# DynamoDB

# ==========================================

module "database" {
  source       = "./modules/database"
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================

# Compute (EC2 PostgreSQL)

# ==========================================

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment

  ami_id   = "ami-05ffe3c48a9991133"
  key_name = "vockey"

  subnet_id      = module.networking.subnet_ids[0]
  postgres_sg_id = module.networking.postgres_sg_id
}

# ==========================================

# IoT Core

# ==========================================

module "iot" {
  source       = "./modules/iot"
  project_name = var.project_name
  environment  = var.environment

  lab_role_arn = data.aws_iam_role.lab_role.arn
  account_id   = data.aws_caller_identity.current.account_id
  region       = data.aws_region.current.name

  iot_endpoint = data.aws_iot_endpoint.iot_endpoint.endpoint_address
  root_ca_pem  = data.http.root_ca.response_body

  sensor_bucket_name = module.storage.sensor_bucket_name
  sensor_table_name  = module.database.sensor_table_name
}
