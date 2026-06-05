import time
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from services.dynamo_service import get_sensor, get_all_sensors, put_sensor, get_recent_events
from services.postgres_service import get_history, health_check as pg_health
from datetime import datetime, timezone

app = FastAPI(
    title="Proyecto IoT API",
    description="API para consulta de sensores IoT — DynamoDB (hot data) + PostgreSQL (histórico)",
    version="1.0.0"
)


class SensorIn(BaseModel):
    device_id:   str
    sensor_type: str
    value:       float


@app.get("/")
def root():
    return {"message": "Proyecto IoT API"}


@app.get("/health")
def health():
    return {
        "status": "ok",
        "postgres": "ok" if pg_health() else "unreachable"
    }


# GET /sensors — lista todos los sensores, último valor por sensor (DynamoDB)
@app.get("/sensors")
def get_sensors():
    items = get_all_sensors()
    return {"sensors": items, "count": len(items)}


# POST /sensors — registra un nuevo evento en DynamoDB
@app.post("/sensors")
def create_sensor(sensor: SensorIn):
    
    ts = datetime.now(timezone.utc).isoformat()

    item = put_sensor(
        device_id=sensor.device_id,
        sensor_type=sensor.sensor_type,
        value=sensor.value,
        timestamp=ts,
    )
    return {"message": "Sensor registrado", "sensor": item}


# GET /sensor/{id}/current — valor en tiempo real desde DynamoDB
@app.get("/sensor/{device_id}/current")
def current(device_id: str):
    sensor = get_sensor(device_id)
    if not sensor:
        raise HTTPException(status_code=404, detail=f"Sensor '{device_id}' no encontrado")
    return sensor


# GET /sensor/{id}/recent — últimos 10 eventos desde DynamoDB
@app.get("/sensor/{device_id}/recent")
def recent(device_id: str):
    items = get_recent_events(device_id, limit=10)
    if not items:
        raise HTTPException(status_code=404, detail=f"No hay eventos para '{device_id}'")
    return {"device_id": device_id, "recent": items, "count": len(items)}


# GET /sensor/{id}/history — histórico completo desde PostgreSQL
@app.get("/sensor/{device_id}/history")
def history(device_id: str):
    try:
        rows = get_history(device_id=device_id, limit=1000)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"No se pudo conectar a PostgreSQL: {str(e)}")
    return {"device_id": device_id, "history": rows, "count": len(rows)}