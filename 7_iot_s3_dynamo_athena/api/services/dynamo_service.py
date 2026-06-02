import os
import boto3
from decimal import Decimal

AWS_REGION   = os.getenv("AWS_REGION", "us-east-1")
DYNAMO_TABLE = os.getenv("DYNAMO_TABLE", "SensorData-lab")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
table    = dynamodb.Table(DYNAMO_TABLE)


def _clean(obj):
    """Convierte Decimal a float para que JSON lo serialice sin errores."""
    if isinstance(obj, list):
        return [_clean(i) for i in obj]
    if isinstance(obj, dict):
        return {k: _clean(v) for k, v in obj.items()}
    if isinstance(obj, Decimal):
        return float(obj)
    return obj


def get_sensor(device_id: str):
    """Devuelve el registro más reciente de un sensor, o None si no existe."""
    response = table.get_item(Key={"device_id": device_id})
    item = response.get("Item")
    return _clean(item) if item else None


def get_all_sensors():
    """Devuelve todos los sensores de la tabla (un registro por sensor = hot data)."""
    response = table.scan()
    return _clean(response.get("Items", []))


def put_sensor(device_id: str, sensor_type: str, value: float, unit: str, timestamp: str):
    """Inserta o actualiza un sensor en DynamoDB (upsert por device_id)."""
    item = {
        "device_id":   device_id,
        "sensor_type": sensor_type,
        "value":       Decimal(str(value)),
        "unit":        unit,
        "timestamp":   timestamp,
    }
    table.put_item(Item=item)
    return _clean(item)