# ==============================================================================
# RUTA: ./Makefile
# CORRECCIÓN: Añadido '-F dwarf' a NASMFLAGS para que GDB pueda mapear
#             instrucciones a líneas de código fuente correctamente.
#             Sin este flag, el depurador de VS Code (launch.json) no puede
#             mostrar el archivo .asm correspondiente durante la depuración.
# CORRECCIÓN: 'clean' ahora solo borra el ejecutable y objeto del comando actual,
#             preservando libcore.a para compilación incremental.
#             'clean-all' borra todo (usar solo si cambias código en lib/).
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

# CORRECCIÓN: Añadido '-F dwarf' para emitir info de depuración en formato
# DWARF, que es el estándar que GDB y VS Code esperan para leer símbolos y
# mapear puntos de ruptura a líneas de fuente en archivos .asm.
NASMFLAGS = -f elf64 -g -F dwarf

# Declaramos reglas que no son archivos para evitar colisiones
.PHONY: all clean clean-all test help install run

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

# Limpia solo el ejecutable y objeto del comando actual.
# Preserva libcore.a para que la siguiente compilación sea incremental.
clean:
	-rm -f $(EXEC) $(OBJ_MAIN) $(DEP_MAIN)

# Limpia absolutamente todo (ejecutables, objetos y librería estática).
# Usar solo cuando se modifica código dentro de lib/.
clean-all:
	-rm -rf $(BIN_DIR)/* $(BUILD_DIR)/*

# Incluimos los archivos .d generados.
# El guion '-' al principio evita que Make falle si los archivos .d aún no existen.
-include $(DEP_MAIN) $(LIB_DEPS)

# ==============================================================================
# TARGETS ADICIONALES
# ==============================================================================

# Help: Mostrar información de targets disponibles
help:
	@echo "NASM Project - Targets disponibles:"
	@echo ""
	@echo "  make all               - Compilar el proyecto (por defecto)"
	@echo "  make SRC=<archivo>     - Compilar un archivo específico"
	@echo "  make clean             - Limpiar objeto y ejecutable actual"
	@echo "  make clean-all         - Limpiar todo (rebuild completo)"
	@echo "  make test              - Ejecutar suite de tests"
	@echo "  make run               - Ejecutar el binario compilado"
	@echo "  make install           - Instalar binario en /usr/local/bin"
	@echo "  make help              - Mostrar esta ayuda"
	@echo ""
	@echo "Ejemplo:"
	@echo "  make SRC=comandos/hello_world/hello_world.asm"

# Test: Ejecutar suite de tests
test:
	@echo "Ejecutando tests..."
	@bash tests/run_tests.sh

# Run: Ejecutar el binario compilado
run: $(EXEC)
	@echo "Ejecutando $(EXEC)..."
	@./$(EXEC)

# Install: Instalar binario en sistema
install: $(EXEC)
	@echo "Instalando $(BASENAME) en /usr/local/bin..."
	@sudo cp $(EXEC) /usr/local/bin/$(BASENAME)
	@echo "Instalado: /usr/local/bin/$(BASENAME)"

# Info: Mostrar variables de compilación
info:
	@echo "Variables de compilación:"
	@echo "  BASENAME   = $(BASENAME)"
	@echo "  EXEC       = $(EXEC)"
	@echo "  SRC        = $(SRC)"
	@echo "  LIB_SRCS   = $(LIB_SRCS)"
	@echo "  LIB_OBJS   = $(LIB_OBJS)"