#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/modules/base.sh"
source "${SCRIPT_DIR}/modules/desktop.sh"
source "${SCRIPT_DIR}/modules/security.sh"
source "${SCRIPT_DIR}/modules/ai.sh"
source "${SCRIPT_DIR}/modules/dev.sh"
source "${SCRIPT_DIR}/modules/hardware.sh"


[[ $EUID -ne 0 ]] || die "No los corras como root"

usage() {
  cat <<EOF
Uso: ${0##*/} [opciones]

Módulos:
  --desktop     entorno i3 + dotfiles + fuente + zsh
  --all         todos los módulos
  --security    herramientas de pentest/bug bounty/CTF
  --dev         herramienta de desarollo
  --ai          claude desktop y claude code
  --hardware    herramienta especificas de hardware

Sin módulos seleccionados, muestra esta ayuda.
EOF
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 0; }

  local do_desktop=false
  local do_security=false
  local do_ai=false
  local do_dev=false
  local do_hardware=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --desktop) do_desktop=true ;;
      --security) do_security=true ;;
      --ai) do_ai=true ;;
      --dev) do_dev=true ;;
      --hardware) do_hardware=true ;;
      --all)      do_desktop=true; do_security=true; do_dev=true; do_ai=true ;;
      -h|--help) usage; exit 0 ;;
      *) die "opción desconocida: $1 (usa --help)" ;;
    esac
    shift
  done

  log "Arrancando setup..."
  enable_repos

  if $do_hardware; then
    install_hardware
  fi

  if $do_desktop; then
    apt_install curl git
    install_shell
    install_desktop
    install_nerd_font
    link_dotfiles
    set_default_shell
  fi

  if $do_security; then
    install_security
  fi

  if $do_ai; then 
    install_claude_desktop
    install_claude_code
  fi

  if $do_dev; then
    log "instalando dev packages..."
    dev_debian_packaging
    install_desktop
  fi

  ok "Todo listo."
}

main "$@"
