.PHONY: default
default:
	@echo "usage: make install"

install:
	mkdir -p "${HOME}/.local/bin"
	cat macenv.sh >"${HOME}/.local/bin/macenv"
	chmod +x "${HOME}/.local/bin/macenv"
