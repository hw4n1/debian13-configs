#!/usr/bin/env bash
# modules/desktop.sh

install_desktop(){
	log "instalando entorno grafico i3..."
	apt_install_list "${REPO_DIR}/packages/desktop.txt"
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

	local fonts
    fonts="$(fc-list 2>/dev/null)"
    if grep -qi "${font} Nerd Font" <<< "$fonts"; then
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

install_shell(){
	log "instalando CLI..."
	apt_install_list "${REPO_DIR}/packages/shell.txt"
	ok "zsh instalado"
}