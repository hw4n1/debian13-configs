#!/usr/bin/env bash
# modules/ai.sh


install_claude_desktop() {
  local list="/etc/apt/sources.list.d/claude-desktop.list"
  local key="/usr/share/keyrings/claude-desktop-archive-keyring.asc"

  if [[ -f "$list" ]]; then
    ok "repo de Claude Desktop ya añadido"
  else
    log "añadiendo repo de Claude Desktop..."
    sudo curl -fsSLo "$key" https://downloads.claude.ai/claude-desktop/key.asc
    echo "deb [arch=amd64,arm64 signed-by=${key}] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
      | sudo tee "$list" >/dev/null
    sudo apt-get update -qq
    ok "repo de Claude Desktop añadido"
  fi

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