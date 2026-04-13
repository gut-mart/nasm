ROOT_DIR = ../..
PROJECT_SRC = comandos/draw_line/draw_line.asm
EXEC_NAME = draw_line

all:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC)

clean:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC) clean

run: all
	@echo "--- EJECUTANDO ---"
	@$(ROOT_DIR)/bin/$(EXEC_NAME)
