#!/bin/bash
# ==============================================================================
# RUTA: ./scripts/fb_run/fb_run.sh
# DESCRIPCIÓN: Oculta el cursor del terminal antes de ejecutar un comando de
#              framebuffer y lo restaura al terminar, independientemente de si
#              el comando tuvo éxito, falló o fue interrumpido.
#
#              Detecta el TTY activo en la consola física (/sys/class/tty/tty0/active)
#              para funcionar correctamente tanto en local como vía SSH.
#
# USO:
#   ./scripts/fb_run/fb_run.sh [--espera] <comando> [argumentos...]
#
#   --espera   Pausa tras el comando hasta que se pulse una tecla.
#              Necesario para comandos de dibujo rápidos: sin esta opción
#              el cursor se oculta y restaura antes de que el ojo lo detecte.
#
# EJEMPLOS:
#   sudo ./scripts/fb_run/fb_run.sh --espera ./bin/draw_line 0 0 1919 1079 0xFFFFFF
#   sudo ./scripts/fb_run/fb_run.sh --espera ./bin/screenshot captura /tmp
# ==============================================================================

ESPERA=0
if [ "$1" = "--espera" ]; then
    ESPERA=1
    shift
fi

# Determinar dónde enviar las secuencias de escape:
#   - En consola local: /dev/ttyN es el terminal actual
#   - Vía SSH: stdout va al cliente remoto; hay que escribir al TTY físico activo
ACTIVE_TTY="/dev/$(cat /sys/class/tty/tty0/active 2>/dev/null)"

if [ -w "$ACTIVE_TTY" ]; then
    TTY_OUT="$ACTIVE_TTY"
else
    TTY_OUT="/dev/tty"
fi

printf '\033[?25l' > "$TTY_OUT"
trap "printf '\033[?25h' > \"$TTY_OUT\"" EXIT INT TERM

"$@"

if [ "$ESPERA" = "1" ]; then
    read -n1 -s -r
fi
