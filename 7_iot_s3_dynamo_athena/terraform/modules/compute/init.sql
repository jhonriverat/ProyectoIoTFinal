CREATE TABLE IF NOT EXISTS eventos_sensores (


    id SERIAL PRIMARY KEY,

    device_id VARCHAR(100) NOT NULL,

    sensor_type VARCHAR(50) NOT NULL,

    value VARCHAR(50) NOT NULL,

    timestamp TIMESTAMP NOT NULL

);
