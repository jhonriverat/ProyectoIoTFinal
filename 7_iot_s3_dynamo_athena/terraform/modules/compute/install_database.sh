#!/bin/bash

# ============================================================

# Script de inicialización de EC2

# Proyecto: ProyectoIoTFinal

# Autor: Equipo Proyecto IoT

#

# Este script se ejecuta automáticamente cuando Terraform

# crea la instancia EC2.

#

# Funciones:

# 1. Actualizar Amazon Linux 2023.

# 2. Instalar Docker y Git.

# 3. Instalar Docker Compose.

# 4. Instalar Docker Buildx.

# 5. Habilitar Docker.

# 6. Clonar el repositorio del proyecto.

# 7. Levantar PostgreSQL mediante Docker Compose.

#

# PostgreSQL almacenará el histórico completo de eventos

# generados por los sensores IoT.

# ============================================================

echo "==========================================="
echo "INICIANDO CONFIGURACIÓN DE LA EC2"
echo "==========================================="

# ------------------------------------------------------------

# 1. Actualizar sistema operativo

# ------------------------------------------------------------

sudo dnf update -y

# ------------------------------------------------------------

# 2. Instalar Docker y Git

# ------------------------------------------------------------

sudo dnf install -y docker git

# ------------------------------------------------------------

# 3. Instalar Docker Compose

# ------------------------------------------------------------

sudo mkdir -p /usr/local/lib/docker/cli-plugins

sudo curl -SL 
"https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" 
-o /usr/local/lib/docker/cli-plugins/docker-compose

sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ------------------------------------------------------------

# 4. Instalar Docker Buildx

# ------------------------------------------------------------

sudo curl -SL 
"https://github.com/docker/buildx/releases/download/v0.17.0/buildx-v0.17.0.linux-amd64" 
-o /usr/local/lib/docker/cli-plugins/docker-buildx

sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# ------------------------------------------------------------

# 5. Habilitar Docker

# ------------------------------------------------------------

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker ec2-user

# ------------------------------------------------------------

# 6. Clonar repositorio del proyecto

# ------------------------------------------------------------

cd /home/ec2-user

git clone https://github.com/jhonriverat/ProyectoIoTFinal.git proyectoFinal

# ------------------------------------------------------------

# 7. Ir al módulo compute

# ------------------------------------------------------------

cd proyectoFinal/terraform/modules/compute

# ------------------------------------------------------------

# 8. Levantar PostgreSQL

# ------------------------------------------------------------

sudo docker compose -f docker-compose-postgres.yml up -d --build

echo "==========================================="
echo "POSTGRESQL DESPLEGADO CORRECTAMENTE"
echo "==========================================="
echo "Base de datos : sensordb"
echo "Puerto        : 5432"
echo "Tabla         : eventos_sensores"
echo "==========================================="
