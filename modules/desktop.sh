#!/usr/bin/env bash

NERD_FONT="JetBrainsMono"

install_shell() {
  log "instalando CLI..."
  apt_install_list "${REPO_DIR}/packages/shell.txt"
  ok "zsh instalado"
}

install_desktop() {
  log "instalando entorno grafico i3..."
  apt_install_list "${REPO_DIR}/packages/desktop.txt"
  ok "escritorio base instalado"
}

DOTFILES=(
  "i3/config|.config/i3/config"
  "polybar/config.ini|.config/polybar/config.ini"
  "polybar/launch.sh|.config/polybar/launch.sh"
  "polybar/vpn.sh|.config/polybar/vpn.sh"
  "picom/picom.conf|.config/picom/picom.conf"
  "dunst/dunstrc|.config/dunst/dunstrc"
  "kitty/kitty.conf|.config/kitty/kitty.conf"
  "rofi/config.rasi|.config/rofi/config.rasi"
  "autorandr/postswitch|.config/autorandr/postswitch"
  "wallpapers/angel.jpg|.config/wallpapers/angel.jpg"
  "zsh/.zshrc|.zshrc"
)

link_dotfiles() {
  log "enlazando dotfiles..."

  local fallidos=0 entrada origen destino
  for entrada in "${DOTFILES[@]}"; do
    origen="${entrada%%|*}"
    destino="${entrada##*|}"
    link_config "$origen" "$HOME/$destino" || fallidos=$((fallidos + 1))
  done

  if [[ $fallidos -gt 0 ]]; then
    warn "$fallidos dotfile(s) no se pudieron enlazar"
    return 1
  fi

  ok "dotfiles enlazados"
}

nerd_font_installed() {
  fc-list 2>/dev/null | grep -qi "${NERD_FONT} Nerd Font"
}

install_nerd_font() {
  if nerd_font_installed; then
    ok "Nerd Font ya instalada"
    return 0
  fi

  command -v unzip >/dev/null 2>&1 || { warn "falta unzip para descomprimir la fuente"; return 1; }

  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.zip"
  local destino="$HOME/.local/share/fonts/${NERD_FONT}"
  local descarga
  descarga="$(mktemp -t "${NERD_FONT}.XXXXXX.zip")"

  log "descargando ${NERD_FONT} Nerd Font..."
  if ! curl -fsSL "$url" -o "$descarga"; then
    rm -f "$descarga"
    warn "no se pudo descargar la fuente (¿sin red?); polybar seguirá con texto"
    return 1
  fi

  mkdir -p "$destino"
  unzip -oq "$descarga" -d "$destino"
  fc-cache -f "$destino" >/dev/null
  rm -f "$descarga"
  ok "Nerd Font instalada"
}

set_default_shell() {
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"

  if [[ -z "$zsh_bin" ]]; then
    warn "zsh no está instalado; no cambio el shell por defecto"
    return 1
  fi

  if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_bin" ]]; then
    ok "zsh ya es el shell por defecto"
    return 0
  fi

  grep -qxF "$zsh_bin" /etc/shells || printf '%s\n' "$zsh_bin" | sudo tee -a /etc/shells >/dev/null

  if sudo chsh -s "$zsh_bin" "$USER"; then
    ok "shell cambiado a zsh (aplica al reiniciar sesión)"
  else
    warn "no se pudo cambiar el shell por defecto"
    return 1
  fi
}
