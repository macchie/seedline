.DEFAULT_GOAL := help

GODOT ?= godot
NPM ?= npm

.PHONY: help godot website website-install website-build website-preview

help:
	@printf '%s\n' \
		'make godot           Run the Godot game' \
		'make website-install Install website dependencies' \
		'make website         Run the Vite development server' \
		'make website-build   Create a production website build' \
		'make website-preview Preview the production website build'

godot:
	$(GODOT) --path .

website-install:
	$(NPM) install --prefix website

website:
	$(NPM) run --prefix website dev

website-build:
	$(NPM) run --prefix website build

website-preview:
	$(NPM) run --prefix website preview
