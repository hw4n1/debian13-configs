#!/usr/bin/env bash
set -euo pipefail

# -- Helpers --

log()	{ printf '[*] %s\n' "$*"; }
ok()	{ printf '[*] %s\n' "$*"; }
warn()	{ printf '[*] %s\n' "$*" >&2; }
die()	{ printf '[*] %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "No los corras como root"


pkg_installed(){
	dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

apt_install(){
	local faltan=()
	local p
	for p in "$@"; do
		if pkg_installed "$p"; then
			ok "ya instalado: $p"
		else
			faltan+=("$p")
		fi
	done


	if [[ ${#faltan[@]} -eq 0 ]]; then
		log "nada que instalar, todo presente"
		return 0
	fi

	log "instalando: ${faltan[*]}"
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${faltan[@]}"

}

main() {
	log "Arrancando setup..."
	apt_install curl git
	ok "Todo listo."
}

main "$@"
