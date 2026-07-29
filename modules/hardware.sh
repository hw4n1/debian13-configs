#!/usr/bin/env bash

install_asusctl() {
  if command -v asusctl >/dev/null 2>&1; then
    ok "asusctl ya instalado ($(asusctl --version 2>/dev/null))"
    return 0
  fi

  log "instalando dependencias de asusctl..."
  apt_install libclang-dev libudev-dev libfontconfig-dev \
    build-essential cmake libxkbcommon-dev

  if ! command -v cargo >/dev/null 2>&1; then
    log "instalando Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
  fi

  local src="$HOME/build/asusctl"
  if [[ ! -d "$src" ]]; then
    log "clonando asusctl..."
    mkdir -p "$HOME/build"
    git clone https://gitlab.com/asus-linux/asusctl.git "$src" \
      || { warn "falló el clonado"; return 1; }
  fi

  log "compilando asusctl (esto tarda)..."
  ( cd "$src" && make ) || { warn "falló la compilacion"; return 1; }
  ( cd "$src" && sudo make install ) || { warn "falló make install"; return 1; }

  sudo systemctl enable --now asusd
  ok "asusctl instalado"
}

install_hardware() {
  install_asusctl
  ok "soporte de hardware completado"
}