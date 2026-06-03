import json
import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs      = boto3.client("sqs", region_name="us-east-1")
QUEUE_URL = os.environ["ALERT_QUEUE_URL"]
THRESHOLD = float(os.environ.get("TEMP_THRESHOLD", "30.0"))


def handler(event, context):
    """
    Regla 3 IoT — se dispara cuando temp > umbral.
    Recibe el payload del sensor y lo publica en SQS como alerta.
    """
    logger.info(f"Evento recibido: {json.dumps(event)}")

    device_id   = event.get("device_id", "unknown")
    sensor_type = event.get("sensor_type", "unknown")
    value       = float(event.get("value", 0))
    timestamp   = event.get("timestamp", "")

    alert_message = {
        "alert":       True,
        "device_id":   device_id,
        "sensor_type": sensor_type,
        "value":       value,
        "threshold":   THRESHOLD,
        "timestamp":   timestamp,
        "message":     f"ALERTA: {device_id} reportó {sensor_type}={value} (umbral={THRESHOLD})"
    }

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(alert_message)
    )

    logger.info(f"Alerta enviada a SQS: {alert_message['message']}")
    return {"statusCode": 200, "body": "Alerta enviada"}