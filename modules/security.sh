#!/usr/bin/env bash
# modules/security.sh

security_apt() {
  log "instalando herramientas de seguridad (apt)..."
  apt_install_list "${REPO_DIR}/packages/security.txt"
  ok "herramientas apt instaladas"
}

install_security() {
  security_apt
  ok "capa de seguridad completada"
}