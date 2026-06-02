resource "aws_dynamodb_table" "sensor_data" {
  name         = "SensorData-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  # Partition Key: device_id — agrupa todos los eventos de un sensor
  # Sort Key: timestamp — permite ordenar y consultar los últimos N eventos
  hash_key  = "device_id"
  range_key = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}