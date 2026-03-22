#!/bin/bash

echo "======================================================="
echo "⚙️  CONFIGURANDO ENTORNO DE DESARROLLO NASM (MANJARO)  "
echo "======================================================="

# 1. Instalar dependencias necesarias
echo "[1/4] Instalando dependencias del sistema..."
sudo pacman -S --needed inotify-tools nasm make gdb gcc

# 2. Dar permisos de ejecución al monitor
echo "[2/4] Preparando scripts..."
chmod +x monitor_proyectos.sh

# 3. Crear el servicio de sistema dinámicamente
echo "[3/4] Creando servicio en segundo plano..."
CURRENT_DIR=$(pwd)
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/monitor_asm.service"

mkdir -p "$SERVICE_DIR"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Monitor de Proyectos Ensamblador (inotify)
After=network.target

[Service]
Type=simple
ExecStart=$CURRENT_DIR/monitor_proyectos.sh
WorkingDirectory=$CURRENT_DIR
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

# 4. Activar y arrancar el servicio
echo "[4/4] Activando automatización..."
systemctl --user daemon-reload
systemctl --user enable monitor_asm.service
systemctl --user restart monitor_asm.service

echo "-------------------------------------------------------"
echo "✅ ¡Todo listo! Ya puedes crear carpetas en proyectos/"
echo "======================================================="