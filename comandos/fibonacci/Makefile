ROOT_DIR = ../..
PROJECT_SRC = comandos/fibonacci/fibonacci.asm
EXEC_NAME = fibonacci

all:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC)

clean:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC) clean

run: all
	@echo "--- EJECUTANDO ---"
	@$(ROOT_DIR)/bin/$(EXEC_NAME)
