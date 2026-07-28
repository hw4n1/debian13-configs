#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/modules/base.sh"
source "${SCRIPT_DIR}/modules/desktop.sh"
source "${SCRIPT_DIR}/modules/security.sh"

[[ $EUID -ne 0 ]] || die "No los corras como root"

usage() {
  cat <<EOF
Uso: ${0##*/} [opciones]

Módulos:
  --desktop     entorno i3 + dotfiles + fuente + zsh
  --all         todos los módulos
  --security    herramientas de pentest/bug bounty/CTF

Sin módulos seleccionados, muestra esta ayuda.
EOF
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 0; }

  local do_desktop=false
  local do_security=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --desktop) do_desktop=true ;;
      --security) do_security=true ;;
      --all)     do_desktop=true ;;
      -h|--help) usage; exit 0 ;;
      *) die "opción desconocida: $1 (usa --help)" ;;
    esac
    shift
  done

  log "Arrancando setup..."
  enable_repos

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

  ok "Todo listo."
}

main "$@"
