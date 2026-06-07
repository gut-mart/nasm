# ==============================================================================
# RUTA: ./Makefile
# DESCRIPCIÓN: Sistema de construcción para NASM con soporte opcional de
#              despliegue, instalación y depuración remota vía SSH.
#
# USO BÁSICO:
#   make SRC=comandos/monitor/draw_pixel/draw_pixel.asm
#   make clean
#   make help
#
# USO REMOTO (requiere config.local.mk):
#   make deploy      SRC=comandos/monitor/draw_pixel/draw_pixel.asm
#   make install     SRC=comandos/monitor/draw_pixel/draw_pixel.asm
#   make install-all                  ← instala todos los comandos de una vez
#
# Para activar deploy/install, copia config.example.mk a config.local.mk
# y rellénalo con tus datos.
# ==============================================================================

SRC ?= main.asm

# --- Extraer el nombre del archivo (ej: fb_core.asm -> fb_core) ---
BASENAME = $(basename $(notdir $(SRC)))

BIN_DIR   = bin
BUILD_DIR = build

# --- Configuración personal (opcional) ---
# Si existe config.local.mk se carga; si no, se ignora silenciosamente.
# El guión inicial '-' hace que Make NO falle cuando el archivo no existe.
-include config.local.mk

# --- Variables dinámicas ---
EXEC       = $(BIN_DIR)/$(BASENAME)
OBJ_MAIN   = $(BUILD_DIR)/$(BASENAME).o
DEP_MAIN   = $(OBJ_MAIN:.o=.d)

# Definimos el nombre de nuestra librería estática
LIB_STATIC = $(BUILD_DIR)/libcore.a

LIB_SRCS = $(shell find lib -name '*.asm')
LIB_OBJS = $(patsubst %.asm, $(BUILD_DIR)/%.o, $(LIB_SRCS))
LIB_DEPS = $(LIB_OBJS:.o=.d)

# Directorio de instalación remoto (~/bin del usuario remoto)
# Se puede sobreescribir en config.local.mk: INSTALL_DIR = /otra/ruta
INSTALL_DIR ?= $(REMOTE_DIR)/bin

# Lista completa de comandos para make install-all
# Añadir aquí cada nuevo comando que deba instalarse en el Tecra.
TODOS_COMANDOS = \
	comandos/monitor/core/fb_core.asm \
	comandos/monitor/draw_pixel/draw_pixel.asm \
	comandos/monitor/draw_rect/draw_rect.asm \
	comandos/monitor/draw_line/draw_line.asm \
	comandos/monitor/draw_circle/draw_circle.asm \
	comandos/monitor/screenshot/screenshot.asm \
	comandos/chrono/bench_rect/bench_rect.asm \
	comandos/tools/math/abs/abs.asm \
	comandos/tools/math/min/min.asm \
	comandos/tools/math/max/max.asm \
	comandos/tools/math/clamp/clamp.asm \
	comandos/tools/math/div/div.asm \
	comandos/tools/math/mod/mod.asm \
	comandos/tools/math/pow/pow.asm

# Flags de NASM: -g (debug), -F dwarf (formato para GDB y VS Code)
NASMFLAGS = -f elf64 -g -F dwarf

.PHONY: all clean clean-all test help run deploy install install-all install-setup info

all: $(EXEC)

$(EXEC): $(OBJ_MAIN) $(LIB_STATIC)
	@mkdir -p $(dir $@)
	ld $< $(LIB_STATIC) -o $@

$(LIB_STATIC): $(LIB_OBJS)
	@mkdir -p $(BUILD_DIR)
	ar rcs $@ $^

# Compilación del archivo principal con generación de dependencias
$(OBJ_MAIN): $(SRC)
	@mkdir -p $(dir $@)
	nasm $(NASMFLAGS) -MD $(DEP_MAIN) $< -o $@

# Compilación de los archivos de la librería con generación de dependencias
$(BUILD_DIR)/%.o: %.asm
	@mkdir -p $(dir $@)
	nasm $(NASMFLAGS) -MD $(@:.o=.d) $< -o $@

# Limpia solo el binario y objeto del comando actual.
# Preserva libcore.a para que la siguiente compilación sea incremental.
clean:
	-rm -f $(EXEC) $(OBJ_MAIN) $(DEP_MAIN)

# Limpia absolutamente todo (binarios, objetos y librería estática).
# Usar cuando se modifica código dentro de lib/.
clean-all:
	-rm -rf $(BIN_DIR)/* $(BUILD_DIR)/*

# Incluimos las dependencias generadas. El '-' evita errores si no existen.
-include $(DEP_MAIN) $(LIB_DEPS)

# ==============================================================================
# TARGETS DE EJECUCIÓN Y DESPLIEGUE
# ==============================================================================

# Ejecuta los tests del proyecto
test:
	@echo "Ejecutando tests..."
	@bash tests/run_tests.sh

# Ejecuta el binario localmente
run: $(EXEC)
	@echo "Ejecutando $(EXEC)..."
	@./$(EXEC)

# Despliega el binario al equipo remoto y arranca gdbserver para depuración.
# Requiere config.local.mk con PC_DESTINO, REMOTE_DIR y GDBSERVER_PORT definidos.
deploy: $(EXEC)
	@if [ -z "$(PC_DESTINO)" ] || [ "$(PC_DESTINO)" = "mi_equipo_remoto" ]; then \
		echo "❌ Error: PC_DESTINO no está configurado."; \
		echo "   Copia config.example.mk a config.local.mk y rellena tus datos."; \
		exit 1; \
	fi
	@echo "--- 🚀 DESPLEGANDO EN $(PC_DESTINO) ---"
	@scp $(EXEC) $(PC_DESTINO):$(REMOTE_DIR)/$(BASENAME)
	@echo "✅ Binario [$(BASENAME)] enviado correctamente."
	@scp scripts/fb_run/fb_run.sh $(PC_DESTINO):$(REMOTE_DIR)/fb_run.sh
	@ssh $(PC_DESTINO) "chmod +x $(REMOTE_DIR)/fb_run.sh"
	@echo "✅ Wrapper [fb_run.sh] enviado correctamente."
	@echo "🧹 Limpiando sesiones de gdbserver previas..."
	@ssh $(PC_DESTINO) "sudo killall -9 gdbserver 2>/dev/null || true"
	@echo "🛰️  Iniciando gdbserver remoto en puerto $(GDBSERVER_PORT)..."
	@ssh $(PC_DESTINO) "nohup gdbserver 0.0.0.0:$(GDBSERVER_PORT) $(REMOTE_DIR)/$(BASENAME) $(ARGS) > /dev/null 2>&1 &"
	@echo "🎯 Equipo remoto en espera. Pulsa F5 en VS Code para comenzar."
	@echo "   Para ejecutar sin depurador: sudo $(REMOTE_DIR)/fb_run.sh $(REMOTE_DIR)/$(BASENAME)"

# Instala un comando concreto en ~/bin del equipo remoto.
# Requiere config.local.mk con PC_DESTINO y REMOTE_DIR definidos.
# Uso: make install SRC=comandos/tools/math/abs/abs.asm
install: $(EXEC)
	@if [ -z "$(PC_DESTINO)" ] || [ "$(PC_DESTINO)" = "mi_equipo_remoto" ]; then \
		echo "❌ Error: PC_DESTINO no está configurado."; \
		echo "   Copia config.example.mk a config.local.mk y rellena tus datos."; \
		exit 1; \
	fi
	@echo "--- 📦 INSTALANDO EN $(PC_DESTINO):$(INSTALL_DIR) ---"
	@ssh $(PC_DESTINO) "mkdir -p $(INSTALL_DIR)"
	@scp $(EXEC) $(PC_DESTINO):$(INSTALL_DIR)/$(BASENAME)
	@ssh $(PC_DESTINO) "chmod +x $(INSTALL_DIR)/$(BASENAME)"
	@echo "✅ [$(BASENAME)] instalado en $(INSTALL_DIR)."
	@scp scripts/fb_run/fb_run.sh $(PC_DESTINO):$(INSTALL_DIR)/fb_run.sh
	@ssh $(PC_DESTINO) "chmod +x $(INSTALL_DIR)/fb_run.sh"
	@echo "✅ [fb_run.sh] instalado en $(INSTALL_DIR)."
	@echo ""
	@echo "   Uso: fb_run.sh --espera $(BASENAME) [argumentos]"

# Compila e instala TODOS los comandos del proyecto en ~/bin del Tecra.
# No necesita SRC. Compila en limpio y despliega en orden.
# Añadir nuevos comandos a la variable TODOS_COMANDOS al inicio del Makefile.
install-all:
	@if [ -z "$(PC_DESTINO)" ] || [ "$(PC_DESTINO)" = "mi_equipo_remoto" ]; then \
		echo "❌ Error: PC_DESTINO no está configurado."; \
		echo "   Copia config.example.mk a config.local.mk y rellena tus datos."; \
		exit 1; \
	fi
	@echo "=== 📦 INSTALANDO TODOS LOS COMANDOS EN $(PC_DESTINO):$(INSTALL_DIR) ==="
	@echo ""
	@$(MAKE) clean-all
	@ssh $(PC_DESTINO) "mkdir -p $(INSTALL_DIR)"
	@for cmd in $(TODOS_COMANDOS); do \
		nombre=$$(basename $$cmd .asm); \
		echo "--- Compilando e instalando: $$nombre ---"; \
		$(MAKE) SRC=$$cmd || exit 1; \
		scp bin/$$nombre $(PC_DESTINO):$(INSTALL_DIR)/$$nombre || exit 1; \
		ssh $(PC_DESTINO) "chmod +x $(INSTALL_DIR)/$$nombre"; \
		echo "✅ $$nombre instalado."; \
		echo ""; \
	done
	@scp scripts/fb_run/fb_run.sh $(PC_DESTINO):$(INSTALL_DIR)/fb_run.sh
	@ssh $(PC_DESTINO) "chmod +x $(INSTALL_DIR)/fb_run.sh"
	@echo "✅ fb_run.sh instalado."
	@echo ""
	@echo "=== ✨ Instalación completa en $(INSTALL_DIR) ==="
	@echo "   Verifica en el Tecra: ls ~/bin/"

# Prepara ~/bin en el Tecra y lo añade al PATH si no está ya.
# Solo necesario la primera vez.
install-setup:
	@if [ -z "$(PC_DESTINO)" ] || [ "$(PC_DESTINO)" = "mi_equipo_remoto" ]; then \
		echo "❌ Error: PC_DESTINO no está configurado."; \
		exit 1; \
	fi
	@echo "--- ⚙️  CONFIGURANDO ~/bin EN $(PC_DESTINO) ---"
	@ssh $(PC_DESTINO) "mkdir -p $(INSTALL_DIR)"
	@ssh $(PC_DESTINO) " \
		SHELL_RC=~/.bashrc; \
		if ! grep -q '$(INSTALL_DIR)' \$$SHELL_RC 2>/dev/null; then \
			echo '' >> \$$SHELL_RC; \
			echo '# NASM commands' >> \$$SHELL_RC; \
			echo 'export PATH=\"$(INSTALL_DIR):\$$PATH\"' >> \$$SHELL_RC; \
			echo '✅ PATH actualizado en' \$$SHELL_RC; \
		else \
			echo 'ℹ️  PATH ya contiene $(INSTALL_DIR), sin cambios.'; \
		fi"
	@echo "✅ Setup completado. Reinicia la sesión en el Tecra o ejecuta:"
	@echo "   source ~/.bashrc"

# Información sobre la configuración actual
info:
	@echo "Configuración actual:"
	@echo "  Archivo Fuente:   $(SRC)"
	@echo "  Ejecutable:       $(EXEC)"
	@echo "  BASENAME:         $(BASENAME)"
	@if [ -n "$(PC_DESTINO)" ] && [ "$(PC_DESTINO)" != "mi_equipo_remoto" ]; then \
		echo "  Destino SSH:      $(PC_DESTINO)"; \
		echo "  Carpeta remota:   $(REMOTE_DIR)"; \
		echo "  Dir instalación:  $(INSTALL_DIR)"; \
		echo "  Puerto gdbserver: $(GDBSERVER_PORT)"; \
	else \
		echo "  Destino SSH:      (sin configurar - ver config.example.mk)"; \
	fi

# Información de uso
help:
	@echo "NASM Project - Comandos disponibles:"
	@echo ""
	@echo "  make SRC=<ruta.asm>        Compila un archivo específico"
	@echo "  make clean                 Limpia binario y objeto del comando actual"
	@echo "  make clean-all             Limpia todo (incluida libcore.a)"
	@echo "  make test                  Ejecuta la suite de tests"
	@echo "  make run                   Ejecuta el binario compilado localmente"
	@echo "  make deploy SRC=<...>      Compila y despliega en equipo remoto (*)"
	@echo "  make install SRC=<...>     Instala un comando en ~/bin del Tecra (*)"
	@echo "  make install-all           Instala todos los comandos en ~/bin (*)"
	@echo "  make install-setup         Prepara ~/bin y PATH (solo primera vez) (*)"
	@echo "  make info                  Muestra la configuración actual"
	@echo "  make help                  Muestra esta ayuda"
	@echo ""
	@echo "Ejemplo:"
	@echo "  make SRC=comandos/monitor/draw_pixel/draw_pixel.asm"
	@echo "  make install-all"
	@echo ""
	@echo "(*) requiere config.local.mk - ver config.example.mk"
