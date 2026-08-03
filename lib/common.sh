#!/usr/bin/env bash

log()  { printf '[*] %s\n' "$*"; }
ok()   { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

pkg_exists_in_repos() {
  apt-cache show "$1" >/dev/null 2>&1
}

apt_install() {
  [[ $# -gt 0 ]] || { log "nada que instalar, lista vacia"; return 0; }

  local por_instalar=() inexistentes=() paquete
  for paquete in "$@"; do
    if pkg_installed "$paquete"; then
      ok "ya instalado: $paquete"
    elif pkg_exists_in_repos "$paquete"; then
      por_instalar+=("$paquete")
    else
      inexistentes+=("$paquete")
    fi
  done

  if [[ ${#inexistentes[@]} -gt 0 ]]; then
    warn "no disponibles en los repos (se omiten): ${inexistentes[*]}"
  fi

  if [[ ${#por_instalar[@]} -eq 0 ]]; then
    log "nada que instalar, todo presente"
    return 0
  fi

  log "instalando: ${por_instalar[*]}"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${por_instalar[@]}"
}

strip_comments_and_blanks() {
  sed -e 's/\r$//' -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" \
    | grep -v '^$'
}

apt_install_list() {
  local lista="$1"
  [[ -f "$lista" ]] || { warn "lista no encontrada: $lista"; return 1; }

  local paquetes
  mapfile -t paquetes < <(strip_comments_and_blanks "$lista")

  if [[ ${#paquetes[@]} -eq 0 ]]; then
    warn "lista vacia: $lista"
    return 0
  fi

  apt_install "${paquetes[@]}"
}

already_linked_to() {
  local enlace="$1" destino="$2"
  [[ -L "$enlace" && "$(readlink -f "$enlace")" == "$destino" ]]
}

backup_path() {
  printf '%s.bak-%s' "$1" "$(date +%s)"
}

link_config() {
  local origen destino respaldo
  origen="$(readlink -f "${REPO_DIR}/config/$1" 2>/dev/null)"
  destino="$2"

  [[ -n "$origen" && -e "$origen" ]] || { warn "no existe en el repo: config/$1"; return 1; }

  if already_linked_to "$destino" "$origen"; then
    ok "ya enlazado: $destino"
    return 0
  fi

  if [[ -e "$destino" || -L "$destino" ]]; then
    respaldo="$(backup_path "$destino")"
    warn "backup de $destino -> $respaldo"
    mv "$destino" "$respaldo"
  fi

  mkdir -p "$(dirname "$destino")"
  ln -s "$origen" "$destino"
  ok "enlazado: $destino -> $origen"
}
