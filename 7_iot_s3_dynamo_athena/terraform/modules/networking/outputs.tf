output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}

output "postgres_sg_id" {
  value = aws_security_group.postgres_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_tasks_sg.id
}

output "target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
output "alb_listener_arn" {
  value = aws_lb_listener.http.arn
}