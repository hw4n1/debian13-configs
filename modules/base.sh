#!/usr/bin/env bash
# modules/base.sh

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
