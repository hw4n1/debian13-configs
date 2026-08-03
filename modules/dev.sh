#!/usr/bin/env bash

dev_debian_packaging() {
  log "instalando kit de packaging de Debian..."
  apt_install_list "${REPO_DIR}/packages/dev.txt"
  ok "kit de packaging instalado"
}

install_dev() {
  dev_debian_packaging || return 1
  ok "entorno de desarrollo completado"
}
