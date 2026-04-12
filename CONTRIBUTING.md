# Contribuyendo al Proyecto NASM

¡Gracias por tu interés en contribuir a este proyecto! Las contribuciones son bienvenidas. A continuación se detalla el proceso.

## Código de Conducta

Se espera que todos los colaboradores sean respetuosos y profesionales. Cualquier comportamiento inapropiado será reportado y tratado con seriedad.

## Cómo Contribuir

### Reportar Bugs

1. Abre un issue en GitHub con el prefijo `[BUG]`
2. Describe el problema con claridad
3. Proporciona los pasos para reproducir
4. Incluye información del sistema (distro, versión de NASM, GCC)
5. Adjunta logs o capturas si es relevante

### Proponer Características

1. Abre un issue en GitHub con el prefijo `[FEATURE]`
2. Describe la característica propuesta
3. Explica el caso de uso
4. Proporciona ejemplos si es posible

### Hacer Pull Requests

1. **Fork** el repositorio
2. **Clone** tu fork localmente
3. **Crea una rama** para tu cambio:
   ```bash
   git checkout -b feature/tu-descripcion
   ```
4. **Realiza tus cambios** siguiendo las convenciones del proyecto
5. **Prueba** tus cambios:
   ```bash
   make clean-all
   make SRC=tu_nuevo_comando.asm
   ./bin/tu_nuevo_comando
   ```
6. **Ejecuta los tests**:
   ```bash
   bash tests/run_tests.sh
   ```
7. **Commit** con mensajes claros:
   ```bash
   git commit -m "Feature: Descripción clara del cambio"
   ```
8. **Push** a tu fork:
   ```bash
   git push origin feature/tu-descripcion
   ```
9. **Abre un Pull Request** describiendo tus cambios

## Convenciones de Código

### Ensamblador

- **Archivos:** Usa extensión `.asm`
- **Comentarios:** En español o inglés (consistentemente)
- **Formato:**
  ```nasm
  ; Sección principal (máx 80 caracteres en bucles)
  mov rax, rbx        ; Comenta el propósito
  call funcion
  ```
- **Indentación:** Tab = 4 espacios
- **Nombres:**
  - Funciones: `snake_case` en minúsculas
  - Etiquetas locales: `.nombre_local`
  - Constantes: `MAYUSCULAS_SEPARADAS_POR_GUION`
- **Estructura de archivo:**
  ```nasm
  ; Encabezado con ruta y descripción
  %include "lib/constants.inc"
  %include "lib/sys_macros.inc"
  
  default rel
  
  extern funcion_externa
  
  section .data
      ; datos inicializados
  
  section .bss
      ; datos no inicializados
  
  section .text
      global funcion_exportada
  ```

### Bash

- Usa `#!/bin/bash` al inicio
- Comenta funciones complejas
- Maneja errores con `set -e`

### Markdown

- Usa markdown limpio y consistente
- Títulos con `#` (no more de 3 niveles)
- Código en bloques con ` ``` `

## Estructura de Directorios

Al agregar nuevas librerías o comandos:

```
lib/componentes/nombre_lib/
├── lib_nombre_lib.asm      ; Implementación
├── lib_nombre_lib.inc       ; Headers (constantes, offsets)
└── README.md               ; Documentación

comandos/categoria/nombre_cmd/
├── nombre_cmd.asm          ; Implementación
└── Makefile                ; Generado automáticamente
```

## Testing

- Cada nueva funcionalidad debe tener un test en `tests/`
- Ejecuta `make test` antes de hacer commit
- Prueba en múltiples escenarios (con/sin argumentos, valores límite)

## Documentación

- Actualiza `docs/` cuando cambies APIs públicas
- Cada librería debe tener documentación en Markdown
- Incluye ejemplos de uso

## Versioning

El proyecto usa [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH` (ej: 1.2.3)
- Mayor: cambios incompatibles
- Menor: nuevas características compaibles
- Patch: fixes de bugs

## Licencia

Al contribuir, aceptas que tu código sea licenciado bajo MIT (ver LICENSE).

## Preguntas

- **Dudas técnicas:** Abre un issue con tag `[QUESTION]`
- **Contacto:** Consulta el README

¡Gracias por contribuir!
