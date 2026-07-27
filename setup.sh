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

install_shell(){
	log "instalando CLI..."
	apt_install \
		zsh zsh-autosuggestions zsh-syntax-highlighting
	ok "zsh instalado"
}



install_desktop(){
	log "instalando entorno grafico i3..."
	apt_install \
		xorg i3 kitty \
		lightdm lightdm-gtk-greeter \
		rofi polybar picom dunst libnotify-bin feh unzip \
		network-manager network-manager-gnome		
	ok "escritorio base instalado"

}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

link_dotfiles(){
	log "enlazado dotfiles..."
	link_config "i3/config"	"$HOME/.config/i3/config"
	link_config "polybar/config.ini"	"$HOME/.config/polybar/config.ini"
	link_config "polybar/launch.sh"	"$HOME/.config/polybar/launch.sh"
	link_config "polybar/vpn.sh"	"$HOME/.config/polybar/vpn.sh"
	link_config "picom/picom.conf"	"$HOME/.config/picom/picom.conf"
	link_config "dunst/dunstrc"	"$HOME/.config/dunst/dunstrc"
	link_config "zsh/.zshrc"	"$HOME/.zshrc"
	link_config "kitty/kitty.conf"	"$HOME/.config/kitty/kitty.conf"
	link_config "rofi/config.rasi"	"$HOME/.config/rofi/config.rasi"
}

install_nerd_font(){
	local font="JetBrainsMono"
	local fontdir="$HOME/.local/share/fonts/${font}"

	if fc-list 2>/dev/null | grep -qi "${font} Nerd Font"; then
		ok "Nerd Font ya instalada"
		return 0
	fi

	log "descargando ${font} Nerd Font..."
	local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
	local tmp="/tmp/${font}.zip"

	if ! curl -fsSL "$url" -o "$tmp"; then
		warn "no se pudo descargar la fuente (¿sin red?); polybar seguirá con texto"
		return 1
	fi

	mkdir -p "$fontdir"
	unzip -oq "$tmp" -d "$fontdir"
	fc-cache -f "$fontdir" >/dev/null
	rm -f "$tmp"
	ok "Nerd Font instalada"
}

set_default_shell(){
	if [[ "$(getent passwd "$USER" | cut -d: -f7)" == *zsh ]]; then
		ok "zsh ya es el shell por defecto"
		return 0
	fi
	grep -q "$(command -v zsh)" /etc/shells || command -v zsh | sudo tee -a /etc/shells >/dev/null
	chsh -s "$(command -v zsh)" && ok "shell ha cambiado a zsh (aplicaa al reiniciar sesión gráfica)"
}


main() {
	log "Arrancando setup..."
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

