output "postgres_public_ip" {
  value       = aws_instance.postgres.public_ip
  description = "IP pública de la EC2 con PostgreSQL"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.api_repo.repository_url
  description = "URL del repositorio ECR"
}

output "ecr_repository_name" {
  value       = aws_ecr_repository.api_repo.name
  description = "Nombre del repositorio ECR"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Nombre del cluster ECS"
}

output "ecs_service_name" {
  value       = aws_ecs_service.api.name
  description = "Nombre del servicio ECS"
}

output "alert_lambda_arn" {
  value       = aws_lambda_function.alert.arn
  description = "ARN de la Lambda Alerta"
}