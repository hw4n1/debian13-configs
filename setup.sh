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

[[ $EUID -ne 0 ]] || die "No lo corras como root"

PASOS_OMITIDOS=()

usage() {
  cat <<EOF
Uso: ${0##*/} [opciones]

Módulos:
  --desktop     entorno i3 + dotfiles + fuente + zsh
  --security    herramientas de pentest/bug bounty/CTF
  --dev         herramientas de desarrollo y packaging Debian
  --ai          Claude Desktop y Claude Code
  --hardware    herramientas específicas de hardware (asusctl)
  --all         todos los módulos

Sin módulos seleccionados, muestra esta ayuda.
EOF
}

run_step() {
  local descripcion="$1"; shift

  if "$@"; then
    return 0
  fi

  warn "paso omitido por error: ${descripcion}"
  PASOS_OMITIDOS+=("$descripcion")
}

report_skipped_steps() {
  [[ ${#PASOS_OMITIDOS[@]} -eq 0 ]] && { ok "Todo listo."; return 0; }

  warn "terminado con ${#PASOS_OMITIDOS[@]} paso(s) omitido(s):"
  local paso
  for paso in "${PASOS_OMITIDOS[@]}"; do
    warn "  - $paso"
  done
  return 1
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
      --desktop)  do_desktop=true ;;
      --security) do_security=true ;;
      --ai)       do_ai=true ;;
      --dev)      do_dev=true ;;
      --hardware) do_hardware=true ;;
      --all)      do_desktop=true; do_security=true; do_dev=true
                  do_ai=true; do_hardware=true ;;
      -h|--help)  usage; exit 0 ;;
      *) die "opción desconocida: $1 (usa --help)" ;;
    esac
    shift
  done

  log "Arrancando setup..."

  run_step "paquetes base"        apt_install curl git ca-certificates unzip
  run_step "repos contrib/non-free" enable_repos
  run_step "zona horaria"         set_timezone

  if $do_hardware; then
    run_step "hardware (asusctl)" install_hardware
  fi

  if $do_desktop; then
    run_step "shell (zsh)"     install_shell
    run_step "escritorio i3"   install_desktop
    run_step "Nerd Font"       install_nerd_font
    run_step "dotfiles"        link_dotfiles
    run_step "zsh por defecto" set_default_shell
  fi

  if $do_security; then
    run_step "capa de seguridad" install_security
  fi

  if $do_ai; then
    run_step "Claude Desktop" install_claude_desktop
    run_step "Claude Code"    install_claude_code
  fi

  if $do_dev; then
    run_step "entorno de desarrollo" install_dev
  fi

  report_skipped_steps
}

main "$@"
