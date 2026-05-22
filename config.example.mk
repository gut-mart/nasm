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
# así que si no existe, Make NO falla. Los targets `deploy`, `install` e `info`
# detectarán que faltan estas variables y mostrarán un mensaje informativo.
# ==============================================================================

# --- Destino remoto para los targets `deploy` e `install` ---
# Alias definido en tu ~/.ssh/config, o bien usuario@host directamente.
# Ejemplos válidos:
#   PC_DESTINO = mi_alias_ssh
#   PC_DESTINO = usuario@192.168.1.X
PC_DESTINO = mi_equipo_remoto

# --- Carpeta de trabajo en el equipo remoto ---
# Ruta absoluta. Usada por `deploy` para copiar el binario temporalmente.
# Asegúrate de que tu usuario remoto tenga permiso de escritura.
REMOTE_DIR = /home/usuario_remoto

# --- Directorio de instalación en el equipo remoto ---
# Los binarios instalados con `make install` se copian aquí.
# Por defecto es ~/bin dentro de REMOTE_DIR. Para que sean accesibles
# como comandos del sistema, esta ruta debe estar en el PATH del Tecra.
# Ejecuta `make install-setup` la primera vez para configurarlo automáticamente.
INSTALL_DIR = /home/usuario_remoto/bin

# --- Puerto de gdbserver para depuración remota ---
# Cambia solo si el 1234 ya está ocupado en tu equipo remoto.
GDBSERVER_PORT = 1234
