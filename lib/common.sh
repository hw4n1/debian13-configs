#!/usr/bin/env bash
# lib/common.sh

log()	{ printf '[*] %s\n' "$*"; }
ok()	{ printf '[*] %s\n' "$*"; }
warn()	{ printf '[*] %s\n' "$*" >&2; }
die()	{ printf '[*] %s\n' "$*" >&2; exit 1; }

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

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


link_config(){
	local src="${REPO_DIR}/config/$1"
	local dest="$2"

	[[ -e "$src" ]] || { warn "no existe en el repo: $src"; return 1; }

	if [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]]; then
		ok "ya enlazado: $dest"
		return 0
	fi


	if [[ -e "$dest" || -L "$dest" ]]; then
		local bak="${dest}.bak-$(date +%s)"
		warn "backup de $dest -> $bak"
		mv "$dest" "$bak"
	fi

	mkdir -p "$(dirname "$dest")"
	ln -s "$src" "$dest"
	ok "enlazado: $dest -> $src"

}