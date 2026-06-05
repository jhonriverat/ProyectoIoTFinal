import os
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Key

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
    """Devuelve el registro más reciente de un sensor (último por timestamp)."""
    response = table.query(
        KeyConditionExpression=Key("device_id").eq(device_id),
        ScanIndexForward=False,  # descendente = más reciente primero
        Limit=1
    )
    items = response.get("Items", [])
    return _clean(items[0]) if items else None


def get_all_sensors():
    """
    Devuelve el último valor de cada sensor.
    Hace un scan y agrupa por device_id quedándose con el más reciente.
    """
    response = table.scan()
    items = _clean(response.get("Items", []))
    # Agrupar por device_id, quedar con el timestamp más alto
    latest = {}
    for item in items:
        did = item["device_id"]
        if did not in latest or item["timestamp"] > latest[did]["timestamp"]:
            latest[did] = item
    return list(latest.values())


def get_recent_events(device_id: str, limit: int = 10):
    """Devuelve los últimos N eventos de un sensor desde DynamoDB."""
    response = table.query(
        KeyConditionExpression=Key("device_id").eq(device_id),
        ScanIndexForward=False,  # descendente = más reciente primero
        Limit=limit
    )
    return _clean(response.get("Items", []))


def put_sensor(device_id: str, sensor_type: str, value: float, timestamp: str):
    """Inserta un evento en DynamoDB (cada llamada crea un nuevo registro)."""
    item = {
        "device_id":   device_id,
        "sensor_type": sensor_type,
        "value":       Decimal(str(value)),
        "timestamp":   timestamp,
    }
    table.put_item(Item=item)
    return _clean(item)