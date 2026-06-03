# ============================================================
# EC2 — PostgreSQL (histórico)
# ============================================================
resource "aws_instance" "postgres" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  key_name = var.key_name

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.postgres_sg_id]

  associate_public_ip_address = true

  user_data = file("${path.module}/install_database.sh")

  tags = {
    Name = "postgres-${var.environment}"
  }
}

# ============================================================
# ECR — Repositorio de imagen Docker para la API
# ============================================================
resource "aws_ecr_repository" "api_repo" {
  name                 = "${var.project_name}-api-repo-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr"
    Environment = var.environment
  }
}

# ============================================================
# ECS — Cluster
# ============================================================
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# ============================================================
# ECS — CloudWatch Logs
# ============================================================
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# ============================================================
# ECS — Task Definition
# La IP de la EC2 se pasa como PG_HOST para que la API conecte
# ============================================================
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${aws_ecr_repository.api_repo.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "AWS_REGION",   value = "us-east-1" },
        { name = "DYNAMO_TABLE", value = var.dynamo_table_name },
        { name = "PG_HOST",      value = aws_instance.postgres.public_ip },
        { name = "PG_PORT",      value = "5432" },
        { name = "PG_USER",      value = "postgres" },
        { name = "PG_PASSWORD",  value = "postgres" },
        { name = "PG_DATABASE",  value = "sensordb" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task-def"
    Environment = var.environment
  }
}

# ============================================================
# ECS — Service
# ============================================================
resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api"
    container_port   = 8000
  }

  depends_on = [var.alb_listener_arn]

  tags = {
    Name        = "${var.project_name}-api-service"
    Environment = var.environment
  }
}

# ============================================================
# Lambda — S3 → PostgreSQL (Hito 2/3)
# ============================================================

# Empaqueta el código de la Lambda + dependencias en un ZIP
# El ZIP se crea localmente antes del terraform apply
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambdas/s3_to_postgres/package"
  output_path = "${path.root}/../lambdas/s3_to_postgres/lambda.zip"
}

resource "aws_lambda_function" "s3_to_postgres" {
  function_name    = "${var.project_name}-s3-to-postgres"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      PG_HOST     = aws_instance.postgres.public_ip
      PG_PORT     = "5432"
      PG_USER     = "postgres"
      PG_PASSWORD = "postgres"
      PG_DATABASE = "sensordb"
    }
  }

  tags = { Name = "${var.project_name}-s3-to-postgres", Environment = var.environment }
}

# Permiso para que S3 invoque la Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_postgres.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.sensor_bucket_arn
}

# Trigger: cuando llega un archivo a S3 → dispara la Lambda
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = var.sensor_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_postgres.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
# ============================================================
# SQS + Lambda Alerta + Lambda CloudWatch (Hito 6)
# ============================================================

# Cola SQS de alertas
resource "aws_sqs_queue" "alerts" {
  name                      = "${var.project_name}-alerts"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 60

  tags = { Name = "${var.project_name}-alerts", Environment = var.environment }
}

# CloudWatch Log Group para Lambda CloudWatch Logger
resource "aws_cloudwatch_log_group" "cloudwatch_logger" {
  name              = "/aws/lambda/${var.project_name}-cloudwatch-logger"
  retention_in_days = 7
}

# Lambda Alerta — empaquetada inline (no necesita dependencias externas)
data "archive_file" "alert_zip" {
  type        = "zip"
  output_path = "${path.root}/../lambdas/alert/lambda.zip"
  source {
    content  = file("${path.root}/../lambdas/alert/handler.py")
    filename = "handler.py"
  }
}

resource "aws_lambda_function" "alert" {
  function_name    = "${var.project_name}-alert"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.alert_zip.output_path
  source_code_hash = data.archive_file.alert_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      ALERT_QUEUE_URL = aws_sqs_queue.alerts.url
      TEMP_THRESHOLD  = "30"
    }
  }

  tags = { Name = "${var.project_name}-alert", Environment = var.environment }
}

# Lambda CloudWatch Logger — empaquetada inline
data "archive_file" "cloudwatch_logger_zip" {
  type        = "zip"
  output_path = "${path.root}/../lambdas/cloudwatch_logger/lambda.zip"
  source {
    content  = file("${path.root}/../lambdas/cloudwatch_logger/handler.py")
    filename = "handler.py"
  }
}

resource "aws_lambda_function" "cloudwatch_logger" {
  function_name    = "${var.project_name}-cloudwatch-logger"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.cloudwatch_logger_zip.output_path
  source_code_hash = data.archive_file.cloudwatch_logger_zip.output_base64sha256
  timeout          = 10

  depends_on = [aws_cloudwatch_log_group.cloudwatch_logger]

  tags = { Name = "${var.project_name}-cloudwatch-logger", Environment = var.environment }
}

# Trigger: SQS → Lambda CloudWatch Logger
resource "aws_lambda_event_source_mapping" "sqs_to_cloudwatch" {
  event_source_arn = aws_sqs_queue.alerts.arn
  function_name    = aws_lambda_function.cloudwatch_logger.arn
  batch_size       = 10
  enabled          = true
}