# ==========================================

# Networking Module

# ==========================================

# Usamos la VPC por defecto de AWS Academy

data "aws_vpc" "default" {
  default = true
}

# Obtenemos las subnets de la VPC por defecto

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ==========================================

# Security Group PostgreSQL

# ==========================================

resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg-${var.environment}"
  description = "Permite acceso SSH y PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
