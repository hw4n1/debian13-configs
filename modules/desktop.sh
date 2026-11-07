#!/usr/bin/env bash

# Fuentes que no vienen por apt: "familia|carpeta|url del zip"
# Maple Mono NF (redondeada, con ligaduras) trae ademas todos los glifos de
# Nerd Fonts, asi que cubre texto e iconos de la terminal, la barra y el prompt.
FUENTES_ZIP=(
  "Maple Mono NF|MapleMono|https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF.zip"
)

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
  "bin/i3-help|.local/bin/i3-help"
  "wallpapers/angel.jpg|.config/wallpapers/angel.jpg"
  "zsh/.zshrc|.zshrc"
  "gtk/settings.ini|.config/gtk-3.0/settings.ini"
  "gtk/gtk.css|.config/gtk-3.0/gtk.css"
  "gtk/settings.ini|.config/gtk-4.0/settings.ini"
  "gtk/gtkrc-2.0|.gtkrc-2.0"
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

fuente_instalada() {
  fc-list 2>/dev/null | grep -qi "$1"
}

instalar_fuente_zip() {
  local familia="$1" carpeta="$2" url="$3"

  if fuente_instalada "$familia"; then
    ok "fuente ya instalada: $familia"
    return 0
  fi

  command -v unzip >/dev/null 2>&1 || { warn "falta unzip para descomprimir $familia"; return 1; }

  local destino="$HOME/.local/share/fonts/${carpeta}"
  local descarga
  descarga="$(mktemp -t "${carpeta}.XXXXXX.zip")"

  log "descargando ${familia}..."
  if ! curl -fsSL "$url" -o "$descarga"; then
    rm -f "$descarga"
    warn "no se pudo descargar ${familia} (¿sin red?); se usará la fuente de reserva"
    return 1
  fi

  mkdir -p "$destino"
  unzip -oq "$descarga" -d "$destino" -x "*.otf" "*/LICENSE*" "*/README*"
  fc-cache -f "$destino" >/dev/null
  rm -f "$descarga"
  ok "fuente instalada: $familia"
}

install_fonts() {
  local fallidos=0 entrada familia carpeta url
  for entrada in "${FUENTES_ZIP[@]}"; do
    IFS='|' read -r familia carpeta url <<<"$entrada"
    instalar_fuente_zip "$familia" "$carpeta" "$url" || fallidos=$((fallidos + 1))
  done

  [[ $fallidos -eq 0 ]]
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
