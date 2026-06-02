# from fastapi import FastAPI
# from services.dynamo_service import get_sensor

# app = FastAPI(
#     title="Proyecto IoT API",
#     description="API para consulta de sensores IoT",
#     version="1.0.0"
# )


# @app.get("/")
# def root():
#     return {
#         "message": "Proyecto IoT API"
#     }


# @app.get("/health")
# def health():
#     return {
#         "status": "ok"
#     }


# @app.get("/sensors")
# def get_sensors():
#     return {
#         "message": "Listado de sensores"
#     }


# @app.post("/sensors")
# def create_sensor(sensor: dict):
#     return {
#         "message": "Sensor registrado",
#         "sensor": sensor
#     }


# @app.get("/current/{device_id}")
# def current(device_id: str):

#     sensor = get_sensor(device_id)

#     if not sensor:
#         raise HTTPException(
#             status_code=404,
#             detail=f"Sensor '{device_id}' no encontrado"
#         )

#     return sensor


# @app.get("/recent")
# def get_recent():
#     return {
#         "message": "Últimos 10 eventos desde DynamoDB"
#     }


# @app.get("/history")
# def get_history():
#     return {
#         "message": "Histórico completo desde PostgreSQL"
#     }


import time
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from services.dynamo_service import get_sensor, get_all_sensors, put_sensor
from services.postgres_service import get_history, health_check as pg_health

app = FastAPI(
    title="Proyecto IoT API",
    description="API para consulta de sensores IoT — DynamoDB (hot data) + PostgreSQL (histórico)",
    version="1.0.0"
)


# ---------------------------------------------------------------------------
# Modelo de entrada para POST /sensors
# ---------------------------------------------------------------------------
class SensorIn(BaseModel):
    device_id:   str
    sensor_type: str
    value:       float
    unit:        str
    timestamp:   str | None = None


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
@app.get("/")
def root():
    return {"message": "Proyecto IoT API"}


@app.get("/health")
def health():
    return {
        "status": "ok",
        "postgres": "ok" if pg_health() else "unreachable"
    }


# ---------------------------------------------------------------------------
# GET /sensors — lista todos los sensores (DynamoDB)
# ---------------------------------------------------------------------------
@app.get("/sensors")
def get_sensors():
    items = get_all_sensors()
    return {"sensors": items, "count": len(items)}


# ---------------------------------------------------------------------------
# POST /sensors — registra un nuevo valor en DynamoDB
# ---------------------------------------------------------------------------
@app.post("/sensors")
def create_sensor(sensor: SensorIn):
    ts = sensor.timestamp or str(int(time.time()))
    item = put_sensor(
        device_id=sensor.device_id,
        sensor_type=sensor.sensor_type,
        value=sensor.value,
        unit=sensor.unit,
        timestamp=ts,
    )
    return {"message": "Sensor registrado", "sensor": item}


# ---------------------------------------------------------------------------
# GET /current/{device_id} — valor actual de un sensor (DynamoDB)
# ---------------------------------------------------------------------------
@app.get("/current/{device_id}")
def current(device_id: str):
    sensor = get_sensor(device_id)
    if not sensor:
        raise HTTPException(
            status_code=404,
            detail=f"Sensor '{device_id}' no encontrado"
        )
    return sensor


# ---------------------------------------------------------------------------
# GET /recent — estado actual de todos los sensores (DynamoDB)
# ---------------------------------------------------------------------------
@app.get("/recent")
def get_recent():
    items = get_all_sensors()
    return {"recent": items, "count": len(items)}


# ---------------------------------------------------------------------------
# GET /history — histórico completo desde PostgreSQL
# ---------------------------------------------------------------------------
@app.get("/history")
def get_history_endpoint(
    device_id: str | None = Query(default=None, description="Filtra por sensor"),
    limit:     int        = Query(default=100,  description="Máximo de registros", ge=1, le=1000),
):
    try:
        rows = get_history(device_id=device_id, limit=limit)
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"No se pudo conectar a PostgreSQL: {str(e)}"
        )
    return {"history": rows, "count": len(rows)}