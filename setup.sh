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



enable_repos() {
	local file pattern
	if [[ -f /etc/apt/sources.list.d/debian.sources ]];  then
		file="/etc/apt/sources.list.d/debian.sources"
		pattern='s/^(Components:.*)$/\1 contrib non-free non-free-firmware/'
	elif [[ -s /etc/apt/sources.list ]]; then
		file="/etc/apt/sources.list"
		pattern='s/ main$/ main contrib non-free non-free-firmware/'
	else
		warn "no encuentro un archivo de fuentes conocido; revisalo a mano"
		return 1
	fi

	if grep -q "contrib" "$file"; then
		ok "repos contrib/non-free ya habilitados"
		return 0
	fi


	log "habilitando contrib/non-free en $file"
	sudo cp "$file" "$file.bak-$(date +%s)"
	sudo sed -i -E "$pattern" "$file"

	log "actualizando indices de apt..."
	sudo apt-get update -qq
	ok "repos habilitados"

}

main() {
	log "Arrancando setup..."
	enable_repos
	apt_install curl git
	ok "Todo listo."
}

main "$@"

