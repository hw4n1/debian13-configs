#!/usr/bin/env bash

COMPONENTES_DEBIAN="main contrib non-free non-free-firmware"

enable_repos() {
  local fuentes patron
  fuentes="$(apt_sources_file)" || {
    warn "no encuentro un archivo de fuentes conocido; revisalo a mano"
    return 1
  }

  if apt_sources_is_deb822 "$fuentes"; then
    patron="s/^(Components:[[:space:]]*)main.*\$/\\1${COMPONENTES_DEBIAN}/"
  else
    patron="s/^(deb(-src)?[[:space:]]+\\S+[[:space:]]+\\S+[[:space:]]+)main.*\$/\\1${COMPONENTES_DEBIAN}/"
  fi

  edit_apt_sources "$fuentes" "$patron" 'contrib' 'repos contrib/non-free'
}

set_timezone() {
  local zona="America/Bogota"

  if [[ "$(timedatectl show -p Timezone --value)" == "$zona" ]]; then
    ok "zona horaria ya es $zona"
  else
    sudo timedatectl set-timezone "$zona"
    ok "zona horaria fijada a $zona"
  fi

  sudo timedatectl set-ntp true
}
