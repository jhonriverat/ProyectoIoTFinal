from fastapi import FastAPI
from services.dynamo_service import get_sensor

app = FastAPI(
    title="Proyecto IoT API",
    description="API para consulta de sensores IoT",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "Proyecto IoT API"
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.get("/sensors")
def get_sensors():
    return {
        "message": "Listado de sensores"
    }


@app.post("/sensors")
def create_sensor(sensor: dict):
    return {
        "message": "Sensor registrado",
        "sensor": sensor
    }


@app.get("/current/{device_id}")
def current(device_id: str):

    sensor = get_sensor(device_id)

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail=f"Sensor '{device_id}' no encontrado"
        )

    return sensor


@app.get("/recent")
def get_recent():
    return {
        "message": "Últimos 10 eventos desde DynamoDB"
    }


@app.get("/history")
def get_history():
    return {
        "message": "Histórico completo desde PostgreSQL"
    }