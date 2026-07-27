#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

[[ $EUID -ne 0 ]] || die "No los corras como root"


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
		network-manager network-manager-gnome \
		firefox-esr autorandr arandr		
	ok "escritorio base instalado"

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
	link_config "autorandr/postswitch"	"$HOME/.config/autorandr/postswitch"
	link_config "wallpapers/angel.jpg"	"$HOME/.config/wallpapers/angel.jpg"
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

