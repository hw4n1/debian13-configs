#!/usr/bin/env bash

# Chroot de sbuild: sid es lo que espera el archivo para subir parches.
SBUILD_SUITE="unstable"
SBUILD_MIRROR="http://deb.debian.org/debian"
SBUILD_CACHE="${HOME}/.cache/sbuild"

DEV_DOTFILES=(
  "devscripts/sbuildrc|.sbuildrc"
  "devscripts/quiltrc-dpkg|.quiltrc-dpkg"
  "devscripts/devscripts|.devscripts"
)

dev_debian_packaging() {
  log "instalando kit de packaging de Debian..."
  apt_install_list "${REPO_DIR}/packages/dev.txt"
  ok "kit de packaging instalado"
}

dev_enable_deb_src() {
  local fuentes patron habilitado
  fuentes="$(apt_sources_file)" || {
    warn "no encuentro un archivo de fuentes conocido; habilita deb-src a mano"
    return 1
  }

  if apt_sources_is_deb822 "$fuentes"; then
    patron='s/^(Types:[[:space:]]*deb)$/\1 deb-src/'
    habilitado='^Types:.*[[:space:]]deb-src'
  else
    patron='s/^#[[:space:]]*(deb-src[[:space:]])/\1/'
    habilitado='^deb-src[[:space:]]'
  fi

  edit_apt_sources "$fuentes" "$patron" "$habilitado" 'deb-src'
}

dev_link_dotfiles() {
  log "enlazando dotfiles de packaging..."

  local fallidos=0 entrada origen destino
  for entrada in "${DEV_DOTFILES[@]}"; do
    origen="${entrada%%|*}"
    destino="${entrada##*|}"
    link_config "$origen" "$HOME/$destino" || fallidos=$((fallidos + 1))
  done

  if [[ $fallidos -gt 0 ]]; then
    warn "$fallidos dotfile(s) de packaging no se pudieron enlazar"
    return 1
  fi

  ok "dotfiles de packaging enlazados"
}

dev_sbuild_chroot() {
  if ! command -v mmdebstrap >/dev/null 2>&1; then
    warn "falta mmdebstrap; no puedo crear el chroot de sbuild"
    return 1
  fi

  # El backend unshare necesita rangos de subuid/subgid para el usuario.
  if ! grep -q "^${USER}:" /etc/subuid || ! grep -q "^${USER}:" /etc/subgid; then
    log "asignando rangos de subuid/subgid a ${USER}..."
    if ! sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"; then
      warn "usermod fallo (se niega si el usuario tiene procesos activos)."
      warn "hazlo desde un TTY o tras reiniciar con:"
      warn "  sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${USER}"
      return 1
    fi
    ok "rangos de subuid/subgid asignados"
  fi

  local arch tarball
  arch="$(dpkg --print-architecture)"
  # sbuild busca el tarball por este nombre exacto; no lo renombres.
  tarball="${SBUILD_CACHE}/${SBUILD_SUITE}-${arch}.tar.zst"

  if [[ -f "$tarball" ]]; then
    ok "chroot de sbuild ya existe: $tarball"
    return 0
  fi

  mkdir -p "$SBUILD_CACHE"

  log "creando chroot ${SBUILD_SUITE}/${arch} (tarda unos minutos)..."
  if ! mmdebstrap --variant=buildd --arch="$arch" "$SBUILD_SUITE" "$tarball" "$SBUILD_MIRROR"; then
    rm -f "$tarball"
    warn "mmdebstrap fallo; el chroot no se creo"
    return 1
  fi

  ok "chroot creado: $tarball"
}
