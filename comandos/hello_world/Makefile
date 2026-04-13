ROOT_DIR = ../..
PROJECT_SRC = comandos/hello_world/hello_world.asm
EXEC_NAME = hello_world

all:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC)

clean:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC) clean

run: all
	@echo "--- EJECUTANDO ---"
	@$(ROOT_DIR)/bin/$(EXEC_NAME)
