import os
import pg8000.native

PG_HOST     = os.getenv("PG_HOST", "localhost")
PG_PORT     = int(os.getenv("PG_PORT", "5432"))
PG_USER     = os.getenv("PG_USER", "postgres")
PG_PASSWORD = os.getenv("PG_PASSWORD", "postgres")
PG_DATABASE = os.getenv("PG_DATABASE", "sensordb")


def _get_conn():
    return pg8000.native.Connection(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASSWORD,
        database=PG_DATABASE,
    )


def get_history(device_id: str = None, limit: int = 100):
    """
    Devuelve el histórico desde la tabla eventos_sensores.
    Si se pasa device_id filtra por ese sensor.
    """
    conn = _get_conn()
    try:
        if device_id:
            rows = conn.run(
                "SELECT id, device_id, sensor_type, value, timestamp "
                "FROM eventos_sensores "
                "WHERE device_id = :device_id "
                "ORDER BY timestamp DESC LIMIT :limit",
                device_id=device_id,
                limit=limit,
            )
        else:
            rows = conn.run(
                "SELECT id, device_id, sensor_type, value, timestamp "
                "FROM eventos_sensores "
                "ORDER BY timestamp DESC LIMIT :limit",
                limit=limit,
            )
        columns = ["id", "device_id", "sensor_type", "value", "timestamp"]
        return [
            {col: (str(val) if hasattr(val, "isoformat") else val)
             for col, val in zip(columns, row)}
            for row in rows
        ]
    finally:
        conn.close()


def health_check():
    """Verifica que la conexión a PostgreSQL funciona."""
    try:
        conn = _get_conn()
        conn.run("SELECT 1")
        conn.close()
        return True
    except Exception:
        return False