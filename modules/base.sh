#!/usr/bin/env bash

enable_repos() {
  local fuentes patron

  if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    fuentes="/etc/apt/sources.list.d/debian.sources"
    patron='s/^(Components:.*)$/\1 contrib non-free non-free-firmware/'
  elif [[ -s /etc/apt/sources.list ]]; then
    fuentes="/etc/apt/sources.list"
    patron='s/ main$/ main contrib non-free non-free-firmware/'
  else
    warn "no encuentro un archivo de fuentes conocido; revisalo a mano"
    return 1
  fi

  if grep -q "contrib" "$fuentes"; then
    ok "repos contrib/non-free ya habilitados"
    return 0
  fi

  log "habilitando contrib/non-free en $fuentes"
  sudo cp "$fuentes" "$(backup_path "$fuentes")"
  sudo sed -i -E "$patron" "$fuentes"

  log "actualizando indices de apt..."
  sudo apt-get update -qq
  ok "repos habilitados"
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
