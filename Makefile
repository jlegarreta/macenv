PREFIX = ${HOME}/.local

.PHONY: default
default:
	@echo "usage: make install"

install:
	@mkdir -p "${PREFIX}/bin"
	@cat macenv.sh >"${PREFIX}/bin/macenv"
	@chmod +x "${PREFIX}/bin/macenv"
	@echo 'Installed macenv to "${PREFIX}/bin"'
	@echo
	@echo 'To add to your PATH, run:'
	@echo 'export PATH="$${HOME}/.local/bin:$${PATH}"'
