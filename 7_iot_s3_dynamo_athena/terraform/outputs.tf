output "iot_endpoint" {
  description = "Endpoint de AWS IoT Core"
  value       = data.aws_iot_endpoint.iot_endpoint.endpoint_address
}

output "postgres_public_ip" {
  description = "IP pública de la EC2 con PostgreSQL"
  value       = module.compute.postgres_public_ip
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR (para docker push)"
  value       = module.compute.ecr_repository_url
}

output "api_url" {
  description = "URL pública de la API FastAPI"
  value       = "http://${module.networking.alb_dns_name}"
}