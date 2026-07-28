#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/modules/base.sh"
source "${SCRIPT_DIR}/modules/desktop.sh"

[[ $EUID -ne 0 ]] || die "No los corras como root"

main() {
	log "Arrancando setup..."
	set_timezone
	enable_repos
	apt_install curl git
	install_shell
	install_desktop
	install_nerd_font
	link_dotfiles
	set_default_shell
	ok "Todo listo."
}

main "$@"

