# ==============================================================================
# RUTA: ./Makefile
# ==============================================================================

SRC ?= main.asm

# --- Extraer el nombre del archivo (ej: fb_core.asm -> fb_core) ---
BASENAME = $(basename $(notdir $(SRC)))

BIN_DIR   = bin
BUILD_DIR = build

# --- Variables dinámicas ---
EXEC       = $(BIN_DIR)/$(BASENAME)
OBJ_MAIN   = $(BUILD_DIR)/$(BASENAME).o
DEP_MAIN   = $(OBJ_MAIN:.o=.d)

# Definimos el nombre de nuestra librería estática
LIB_STATIC = $(BUILD_DIR)/libcore.a

LIB_SRCS = $(shell find lib -name '*.asm')
LIB_OBJS = $(patsubst %.asm, $(BUILD_DIR)/%.o, $(LIB_SRCS))
LIB_DEPS = $(LIB_OBJS:.o=.d)

# Banderas globales para facilitar modificaciones futuras
NASMFLAGS = -f elf64 -g

# Declaramos reglas que no son archivos para evitar colisiones
.PHONY: all clean

all: $(EXEC)

$(EXEC): $(OBJ_MAIN) $(LIB_STATIC)
	@mkdir -p $(dir $@)
	ld $< $(LIB_STATIC) -o $@

$(LIB_STATIC): $(LIB_OBJS)
	@mkdir -p $(BUILD_DIR)
	ar rcs $@ $^

# Compilación del archivo principal (dinámico) con generación de dependencias
$(OBJ_MAIN): $(SRC)
	@mkdir -p $(dir $@)
	nasm $(NASMFLAGS) -MD $(DEP_MAIN) $< -o $@

# Compilación de los archivos de la librería con generación de dependencias
$(BUILD_DIR)/%.o: %.asm
	@mkdir -p $(dir $@)
	nasm $(NASMFLAGS) -MD $(@:.o=.d) $< -o $@

clean:
	-rm -rf $(BIN_DIR)/* $(BUILD_DIR)/*

# Incluimos los archivos .d generados.
# El guion '-' al principio evita que Make falle si los archivos .d aún no existen.
-include $(DEP_MAIN) $(LIB_DEPS)