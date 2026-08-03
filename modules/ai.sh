#!/usr/bin/env bash

CLAUDE_LIST="/etc/apt/sources.list.d/claude-desktop.list"
CLAUDE_KEY="/usr/share/keyrings/claude-desktop-archive-keyring.asc"
CLAUDE_REPO="https://downloads.claude.ai/claude-desktop"

add_claude_repo() {
  if [[ -f "$CLAUDE_LIST" && -s "$CLAUDE_KEY" ]]; then
    ok "repo de Claude Desktop ya añadido"
    return 0
  fi

  log "añadiendo repo de Claude Desktop..."
  if ! sudo curl -fsSLo "$CLAUDE_KEY" "${CLAUDE_REPO}/key.asc"; then
    warn "no se pudo descargar la clave del repo de Claude Desktop"
    return 1
  fi

  printf 'deb [arch=amd64,arm64 signed-by=%s] %s/apt/stable stable main\n' \
    "$CLAUDE_KEY" "$CLAUDE_REPO" | sudo tee "$CLAUDE_LIST" >/dev/null

  sudo apt-get update -qq
  ok "repo de Claude Desktop añadido"
}

install_claude_desktop() {
  add_claude_repo || return 1
  apt_install claude-desktop
}

install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code CLI ya instalado ($(claude --version 2>/dev/null))"
    return 0
  fi

  log "instalando Claude Code CLI..."
  if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "Claude Code CLI instalado"
  else
    warn "falló la instalación de Claude Code CLI"
    return 1
  fi
}
