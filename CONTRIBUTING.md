# Cómo contribuir

Antes de nada: gracias por interesarte en este proyecto. Esto no es una
biblioteca seria con departamento de mantenimiento — es un proyecto personal
de aprendizaje de NASM. Eso significa que las contribuciones son bienvenidas,
pero también que el ritmo y los criterios son los de un proyecto pequeño.

## Antes de invertir tu tiempo

Si quieres proponer un cambio grande (un comando nuevo, refactor de una
librería, cambio de arquitectura), **abre un issue antes** de ponerte a
codificar. Así evitamos que escribas algo que luego no encaje con la dirección
del proyecto.

Para fixes pequeños y bugs evidentes, no hace falta — manda directamente el
Pull Request.

## Reportar un bug

Abre un issue con esta información:

- Qué hiciste (los comandos exactos).
- Qué esperabas que pasara.
- Qué pasó en realidad.
- Distribución y versión de NASM (`nasm --version`).
- Si afecta al hardware: modelo del equipo y resolución del framebuffer
  (`fbset` en el equipo afectado).

Adjunta la salida tal cual, no la resumas. Los detalles importan.

## Hacer un Pull Request

El flujo estándar:

1. Fork del repo.
2. Rama nueva: `git checkout -b fix/descripcion-corta`.
3. Tus cambios.
4. Probar que compila: `make clean-all && make SRC=ruta/al/archivo.asm`.
5. Probar que los tests pasan: `make test`.
6. Si el cambio afecta al framebuffer, probarlo visualmente en hardware real.
7. Commit con mensaje claro (ver convenciones abajo).
8. Push a tu fork.
9. Pull Request describiendo el cambio.

## Convenciones de código

### Ensamblador

- Comentarios en español (igual que el resto del proyecto).
- Cabecera de archivo con la ruta y una descripción corta:
  ```nasm
  ; ==============================================================================
  ; RUTA: ./lib/algo/lib_algo.asm
  ; DESCRIPCIÓN: Una frase explicando qué hace.
  ; ==============================================================================
  ```
- Nombres de funciones globales: `snake_case` minúscula, con prefijo `lib_`
  si es de librería.
- Etiquetas locales: `.snake_case`.
- Indentación con 4 espacios o 1 tab (consistente dentro del archivo).
- Si añades una función pública, documenta los registros de entrada y salida
  encima de la función.

### Bash

- `#!/bin/bash` al inicio.
- `set -e` si el script no debe seguir tras un error.
- Comentarios en cabecera explicando qué hace.

### Mensajes de commit

Estilo "Conventional Commits" simplificado:

```
tipo(ámbito): resumen corto en imperativo

Detalles si hacen falta. Qué cambia y por qué.
```

Tipos comunes: `fix`, `feat`, `docs`, `chore`, `refactor`. Ámbito opcional.

Ejemplos reales del proyecto:

- `fix(graph): corregir offset X en pixelfast`
- `chore: sanear repositorio - quitar archivos que deben ignorarse`
- `feat(build): parametrizar despliegue remoto vía config.local.mk`

## Reglas no negociables

Estas son las decisiones de diseño del proyecto. Las contribuciones que las
rompan no se aceptarán:

1. **Sin librerías externas.** Nada de libc, nada de SDL, nada de printf.
   Solo syscalls Linux directas. Es la razón de ser del proyecto.
2. **x86_64 Linux.** No hay planes de portar a otras arquitecturas.
3. **Pruebas reales en hardware sin entorno gráfico.** El framebuffer no
   funciona bien con Wayland/X corriendo. Las pruebas que tocan `/dev/fb0`
   deben hacerse desde TTY o por SSH a un equipo headless.

## Licencia

Al contribuir aceptas que tu código se distribuya bajo la licencia MIT
del proyecto. No hay CLA ni paperwork, basta con que mandes el PR.

## Dudas

Abre un issue con la etiqueta `[QUESTION]` o pregunta directamente en el
PR si surge sobre la marcha.
