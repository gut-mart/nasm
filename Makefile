SRC ?= main.asm

BIN_DIR   = bin
BUILD_DIR = build

EXEC       = $(BIN_DIR)/main
OBJ_MAIN   = $(BUILD_DIR)/main.o
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

# Compilación del archivo principal (main.asm) con generación de dependencias
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
# El guion '-' al principio evita que Make falle si los archivos .d aún no existen (ej. primera compilación).
-include $(DEP_MAIN) $(LIB_DEPS)