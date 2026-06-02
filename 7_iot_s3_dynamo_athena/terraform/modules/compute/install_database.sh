#!/bin/bash
 
echo "==========================================="
echo "INICIANDO CONFIGURACIÓN DE LA EC2"
echo "==========================================="
 
# 1. Actualizar sistema operativo
sudo dnf update -y
 
# 2. Instalar Docker y Git
sudo dnf install -y docker git
 
# 3. Instalar Docker Compose
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
 
# 4. Habilitar Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
 
# 5. Clonar repositorio del proyecto
cd /home/ec2-user
git clone https://github.com/jhonriverat/ProyectoIoTFinal.git proyectoFinal
 
# 6. Levantar PostgreSQL
cd proyectoFinal/7_iot_s3_dynamo_athena/terraform/modules/compute
sudo docker compose -f docker-compose-postgres.yml up -d
 
echo "==========================================="
echo "POSTGRESQL DESPLEGADO CORRECTAMENTE"
echo "==========================================="
echo "Base de datos : sensordb"
echo "Puerto        : 5432"
echo "Tabla         : eventos_sensores"
echo "==========================================="
 