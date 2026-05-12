# fb_run

Script auxiliar para ejecutar binarios de framebuffer con gestión automática del cursor de terminal.

## Función

Oculta el cursor del terminal antes de lanzar un comando y lo restaura al terminar, sin importar si el comando tuvo éxito, falló o fue interrumpido (`EXIT`, `INT`, `TERM`).

Detecta el TTY físico activo mediante `/sys/class/tty/tty0/active`, lo que permite funcionar correctamente tanto en consola local como al conectarse vía SSH.

## Uso

```bash
sudo ./scripts/fb_run/fb_run [--espera] <comando> [argumentos...]
```

| Opción | Descripción |
|--------|-------------|
| `--espera` | Pausa tras el comando hasta que se pulse una tecla. Útil para comandos de dibujo rápidos donde el resultado desaparecería antes de poder verse. |

## Ejemplos

```bash
# Dibujar una línea blanca y esperar confirmación
sudo ./scripts/fb_run/fb_run --espera ./bin/draw_line 0 0 1919 1079 0xFFFFFF

# Tomar una captura de pantalla
sudo ./scripts/fb_run/fb_run --espera ./bin/screenshot captura /tmp
```

## Por qué existe

Los binarios que escriben directamente al framebuffer (`/dev/fb0`) pueden dejar el cursor visible en mitad de la pantalla o parpadear durante la ejecución. `fb_run` centraliza esta gestión para que cada binario no tenga que ocuparse de las secuencias de escape del terminal.
