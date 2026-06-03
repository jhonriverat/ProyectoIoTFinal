import json
import os
import boto3
import pg8000.native

# Variables de entorno inyectadas por Terraform
PG_HOST     = os.environ["PG_HOST"]
PG_PORT     = int(os.environ.get("PG_PORT", "5432"))
PG_USER     = os.environ.get("PG_USER", "postgres")
PG_PASSWORD = os.environ.get("PG_PASSWORD", "postgres")
PG_DATABASE = os.environ.get("PG_DATABASE", "sensordb")

s3 = boto3.client("s3")


def get_conn():
    return pg8000.native.Connection(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASSWORD,
        database=PG_DATABASE,
    )


def handler(event, context):
    """
    Se activa cuando S3 recibe un nuevo archivo JSON (trigger ObjectCreated).
    Lee el JSON del bucket, extrae los campos del sensor e inserta en PostgreSQL.
    """
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key    = record["s3"]["object"]["key"]

        print(f"Procesando: s3://{bucket}/{key}")

        # Leer el JSON desde S3
        response = s3.get_object(Bucket=bucket, Key=key)
        body     = response["Body"].read().decode("utf-8")
        payload  = json.loads(body)

        print(f"Payload recibido: {payload}")

        # Extraer campos — el payload tiene la estructura que envía el sensor
        device_id   = payload.get("device_id")
        sensor_type = payload.get("sensor_type")
        value       = str(payload.get("value"))
        timestamp   = payload.get("timestamp")

        if not all([device_id, sensor_type, value, timestamp]):
            print(f"Payload incompleto, se omite: {payload}")
            continue

        # Insertar en PostgreSQL
        conn = get_conn()
        try:
            conn.run(
                "INSERT INTO eventos_sensores (device_id, sensor_type, value, timestamp) "
                "VALUES (:device_id, :sensor_type, :value, :timestamp::timestamp)",
                device_id=device_id,
                sensor_type=sensor_type,
                value=value,
                timestamp=timestamp,
            )
            print(f"Insertado en PostgreSQL: {device_id} - {sensor_type} = {value}")
        finally:
            conn.close()

    return {"statusCode": 200, "body": "OK"}