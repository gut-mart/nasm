ROOT_DIR = ../../..
PROJECT_SRC = comandos/monitor/draw_rect/draw_rect.asm
EXEC_NAME = draw_rect

all:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC)

clean:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC) clean

run: all
	@echo "--- EJECUTANDO ---"
	@$(ROOT_DIR)/bin/$(EXEC_NAME)
