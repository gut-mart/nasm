# ==============================================================================
# MAKEFILE DINÁMICO PARA ENSAMBLADOR X86_64 (NASM)
# ==============================================================================

# --- 1. CONFIGURACIÓN DE VARIABLES ---

# Archivo principal a compilar (VS Code pasará esto automáticamente)
# Si no se pasa nada, intenta buscar 'demo.asm' o falla suavemente.
SRC ?= demo.asm

# Directorios
BUILD_DIR = build
LIB_DIR   = lib

# Herramientas
ASM = nasm
LD  = ld

# Flags de NASM
# -f elf64: Formato de archivo Linux 64-bits
# -g -F dwarf: Información de depuración para GDB
# -I./ -I./lib/: Rutas para buscar archivos %include
ASM_FLAGS = -f elf64 -g -F dwarf -I./ -I./$(LIB_DIR)/

# Flags del Linker (ld)
LD_FLAGS = -m elf_x86_64

# --- 2. CÁLCULO AUTOMÁTICO DE ARCHIVOS ---

# Nombre base del ejecutable (ej: 'demo.asm' -> 'demo')
# $(notdir ...) quita la ruta, $(basename ...) quita la extensión .asm
TARGET_NAME = $(basename $(notdir $(SRC)))
TARGET_EXEC = $(BUILD_DIR)/$(TARGET_NAME)
TARGET_OBJ  = $(BUILD_DIR)/$(TARGET_NAME).o

# Encontrar TODAS las librerías .asm en la carpeta lib/ recursivamente
LIB_SRCS := $(shell find $(LIB_DIR) -name '*.asm' 2>/dev/null)

# Generar la lista de objetos (.o) esperados para las librerías
# Ejemplo: lib/text/print.asm -> build/lib/text/print.o
LIB_OBJS := $(patsubst %.asm, $(BUILD_DIR)/%.o, $(LIB_SRCS))

# --- 3. REGLAS DE CONSTRUCCIÓN ---

.PHONY: all clean directories

# Regla por defecto
all: directories $(TARGET_EXEC)

# Regla para crear directorios necesarios en build/
directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(dir $(LIB_OBJS))

# --- LINKING (Vincular todo) ---
# Crea el ejecutable final juntando el objeto principal + todos los objetos de lib
$(TARGET_EXEC): $(TARGET_OBJ) $(LIB_OBJS)
	@echo "[LD] Vinculando ejecutable: $@"
	@$(LD) $(LD_FLAGS) -o $@ $^

# --- ENSAMBLADO DEL PROGRAMA PRINCIPAL ---
$(TARGET_OBJ): $(SRC)
	@echo "[ASM] Ensamblando archivo principal: $<"
	@$(ASM) $(ASM_FLAGS) -o $@ $<

# --- ENSAMBLADO DE LAS LIBRERÍAS ---
# Regla genérica para cualquier .asm dentro de lib/
$(BUILD_DIR)/%.o: %.asm
	@echo "[ASM] Ensamblando librería: $<"
	@mkdir -p $(dir $@)
	@$(ASM) $(ASM_FLAGS) -o $@ $<

# --- LIMPIEZA ---
clean:
	@echo "[CLEAN] Borrando carpeta build/"
	@rm -rf $(BUILD_DIR)