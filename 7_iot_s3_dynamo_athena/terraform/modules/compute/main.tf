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
