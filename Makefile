.PHONY: all build run stop install uninstall dmg clean

all: build

build:
	@chmod +x build.sh
	@./build.sh

run: build
	@echo "🚀 Iniciando Codex Touch Bar..."
	@open CodexTouchBar.app

stop:
	@echo "🛑 Deteniendo Codex Touch Bar..."
	@-pkill -f CodexTouchBar || true

install:
	@chmod +x install.sh
	@./install.sh

uninstall:
	@chmod +x uninstall.sh
	@./uninstall.sh

dmg:
	@chmod +x package_dmg.sh
	@./package_dmg.sh

clean:
	@echo "🧹 Limpiando..."
	@rm -rf CodexTouchBar.app build_dmg_staging *.dmg
