variable "project_name"      { type = string }
variable "environment"       { type = string }

# EC2 PostgreSQL
variable "ami_id"            { type = string }
variable "key_name"          { type = string }
variable "subnet_id"         { type = string }
variable "postgres_sg_id"    { type = string }

# ECS
variable "lab_role_arn"      { type = string }
variable "dynamo_table_name" { type = string }
variable "subnet_ids"        { type = list(string) }
variable "ecs_sg_id"         { type = string }
variable "target_group_arn"  { type = string }
variable "alb_listener_arn"  { type = string }

# lamdla
variable "sensor_bucket_name" { type = string }
variable "sensor_bucket_arn"  { type = string }