output "postgres_public_ip" {
  value = aws_instance.postgres.public_ip
}
