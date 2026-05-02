# ==============================================================================
# RUTA: ./config.example.mk
# DESCRIPCIÓN: Plantilla de configuración personal para despliegue remoto.
#
# USO:
#   1. Copia este archivo a config.local.mk:
#        cp config.example.mk config.local.mk
#   2. Edita config.local.mk con tus valores reales.
#   3. config.local.mk está en .gitignore y NO se subirá al repositorio.
#
# El Makefile principal hace `-include config.local.mk` (con guión inicial),
# así que si no existe, Make NO falla. Los targets `deploy` e `info`
# detectarán que faltan estas variables y mostrarán un mensaje informativo.
# ==============================================================================

# --- Destino remoto para el target `deploy` ---
# Alias definido en tu ~/.ssh/config, o bien usuario@host directamente.
# Ejemplos válidos:
#   PC_DESTINO = mi_alias_ssh
#   PC_DESTINO = isidro@192.168.1.158
PC_DESTINO = mi_equipo_remoto

# --- Carpeta donde se copia el binario en el equipo remoto ---
# Ruta absoluta. Asegúrate de que tu usuario remoto tenga permiso de
# escritura en esta carpeta.
REMOTE_DIR = /home/usuario_remoto

# --- Puerto de gdbserver para depuración remota ---
# Cambia solo si el 1234 ya está ocupado en tu equipo remoto.
GDBSERVER_PORT = 1234