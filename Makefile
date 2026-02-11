# ==============================================================================
# MAKEFILE: BINARIOS EN LA CARPETA DEL CÓDIGO FUENTE
# ==============================================================================

# --- 1. CONFIGURACIÓN ---
# Archivo principal (pasado por VS Code automáticamente vía tasks.json)
SRC ?= demo.asm

# Directorios de soporte
BUILD_DIR = build
LIB_DIR   = lib

# Herramientas y Flags
ASM = nasm
LD  = ld
ASM_FLAGS = -f elf64 -g -F dwarf -I./ -I./$(LIB_DIR)/
LD_FLAGS  = -m elf_x86_64

# --- 2. CÁLCULO DE RUTAS (LÓGICA ACTUALIZADA) ---

# TARGET_EXEC: Mantiene la ruta del SRC pero sin extensión
# Ejemplo: proyectos/mi_juego/main.asm -> proyectos/mi_juego/main
TARGET_EXEC = $(basename $(SRC))

# TARGET_OBJ: Mantiene la ruta del SRC pero con extensión .o
# Ejemplo: proyectos/mi_juego/main.asm -> proyectos/mi_juego/main.o
TARGET_OBJ  = $(basename $(SRC)).o

# --- LIBRERÍAS (Estas se quedan en build/ para limpieza) ---
LIB_SRCS := $(shell find $(LIB_DIR) -name '*.asm' 2>/dev/null)
LIB_OBJS := $(patsubst %.asm, $(BUILD_DIR)/%.o, $(LIB_SRCS))

# --- 3. REGLAS ---

.PHONY: all clean directories

all: directories $(TARGET_EXEC)

directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(dir $(LIB_OBJS))

# --- VINCULACIÓN (LINKING) ---
# Crea el ejecutable final en la carpeta de origen
$(TARGET_EXEC): $(TARGET_OBJ) $(LIB_OBJS)
	@echo "[LD] Generando ejecutable: $@"
	@$(LD) $(LD_FLAGS) -o $@ $^

# --- ENSAMBLADO PRINCIPAL (EN TU CARPETA) ---
# Crea el .o en la carpeta de origen
$(TARGET_OBJ): $(SRC)
	@echo "[ASM] Ensamblando archivo local: $<"
	@$(ASM) $(ASM_FLAGS) -o $@ $<

# --- ENSAMBLADO DE LIBRERÍAS (EN BUILD) ---
$(BUILD_DIR)/%.o: %.asm
	@echo "[ASM] Ensamblando librería: $<"
	@mkdir -p $(dir $@)
	@$(ASM) $(ASM_FLAGS) -o $@ $<

# --- LIMPIEZA ---
# Borra la carpeta build Y TAMBIÉN los archivos generados localmente

# --- LIMPIEZA PROFUNDA (MODO ESCANER) ---
clean:
	@echo "[CLEAN] 1. Eliminando carpeta de librerías (build/)..."
	@rm -rf $(BUILD_DIR)

	@echo "[CLEAN] 2. Buscando y eliminando TODOS los archivos .o dispersos..."
	@find . -type f -name "*.o" -not -path "*/.git/*" -delete

	@echo "[CLEAN] 3. Eliminando ejecutables asociados a archivos .asm..."
	# Esta linea busca todos los archivos .asm, les quita la extensión
	# y borra el archivo ejecutable correspondiente si existe.
	@find . -type f -name "*.asm" -not -path "*/build/*" \
		| sed 's/\.asm$$//' \
		| xargs rm -f

	@echo "[LISTO] Proyecto limpio."