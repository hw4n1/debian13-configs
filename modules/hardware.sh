#!/usr/bin/env bash

ASUSCTL_SRC="$HOME/build/asusctl"

ensure_rust() {
  command -v cargo >/dev/null 2>&1 && return 0

  log "instalando Rust via rustup..."
  if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    warn "falló la instalación de rustup"
    return 1
  fi

  source "$HOME/.cargo/env"
}

clone_asusctl() {
  [[ -d "$ASUSCTL_SRC" ]] && return 0

  log "clonando asusctl..."
  mkdir -p "$(dirname "$ASUSCTL_SRC")"
  git clone https://gitlab.com/asus-linux/asusctl.git "$ASUSCTL_SRC" \
    || { warn "falló el clonado"; return 1; }
}

install_asusctl() {
  if command -v asusctl >/dev/null 2>&1; then
    ok "asusctl ya instalado ($(asusctl --version 2>/dev/null))"
    return 0
  fi

  log "instalando dependencias de asusctl..."
  apt_install libclang-dev libudev-dev libfontconfig-dev \
    build-essential cmake pkg-config libxkbcommon-dev

  ensure_rust  || return 1
  clone_asusctl || return 1

  log "compilando asusctl (esto tarda)..."
  ( cd "$ASUSCTL_SRC" && make ) || { warn "falló la compilación"; return 1; }
  ( cd "$ASUSCTL_SRC" && sudo make install ) || { warn "falló make install"; return 1; }

  sudo systemctl enable --now asusd
  ok "asusctl instalado"
}

install_hardware() {
  install_asusctl || return 1
  ok "soporte de hardware completado"
}
