.PHONY: all install uninstall build flatpak flatpak-dev flatpak-run
PREFIX ?= /usr
release ?=

all: build

build:
	meson setup builddir --prefix=$(PREFIX)
	meson configure builddir -Ddevel=$(if $(release),false,true)
	meson compile -C builddir

install:
	meson install -C builddir

uninstall:
	sudo ninja uninstall -C builddir

flatpak:
	flatpak-builder --user --install --force-clean build com.github.leggettc18.pachy.yml

flatpak-dev:
	flatpak-builder --user --install --force-clean build build-aux/com.github.leggettc18.pachy.Devel.yml

flatpak-run:
	G_MESSAGES_DEBUG=all flatpak run com.github.leggettc18.pachy
