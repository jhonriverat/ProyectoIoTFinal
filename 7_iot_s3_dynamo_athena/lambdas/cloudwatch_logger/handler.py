import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """
    Consume mensajes de SQS y escribe Log de Urgencia en CloudWatch.
    El Event Source Mapping borra el mensaje de SQS automáticamente si no hay error.
    """
    for record in event.get("Records", []):
        message_body = record.get("body", "{}")
        message_id   = record.get("messageId", "unknown")

        try:
            alert = json.loads(message_body)
        except json.JSONDecodeError:
            logger.error(f"Mensaje no es JSON válido: {message_body}")
            continue

        # Log de Urgencia — aparece en CloudWatch Logs
        logger.warning(
            f"🚨 LOG DE URGENCIA | "
            f"ID={message_id} | "
            f"device={alert.get('device_id')} | "
            f"tipo={alert.get('sensor_type')} | "
            f"valor={alert.get('value')} | "
            f"umbral={alert.get('threshold')} | "
            f"ts={alert.get('timestamp')} | "
            f"msg={alert.get('message')}"
        )

    return {
        "statusCode": 200,
        "body": json.dumps("Alertas procesadas")
    }