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

ZSHRC_LOCAL="${HOME}/.zshrc.local"

gpg_uid_primaria() {
  gpg --list-secret-keys --with-colons 2>/dev/null \
    | awk -F: '$1 == "uid" { print $10; exit }'
}

nombre_de_uid() { sed -E 's/ *[(<].*//' <<<"$1"; }
correo_de_uid() { sed -nE 's/.*<([^>]+)>.*/\1/p' <<<"$1"; }

dev_identidad_packaging() {
  if [[ -f "$ZSHRC_LOCAL" ]] && grep -q '^export DEBEMAIL=' "$ZSHRC_LOCAL"; then
    ok "identidad de packaging ya definida en $ZSHRC_LOCAL"
    return 0
  fi

  local uid nombre correo
  uid="$(gpg_uid_primaria)"
  nombre="$(nombre_de_uid "$uid")"
  correo="$(correo_de_uid "$uid")"

  [[ -n "$nombre" ]] || nombre="$(git config --get user.name || true)"
  [[ -n "$correo" ]] || correo="$(git config --get user.email || true)"

  if [[ -z "$nombre" || -z "$correo" ]]; then
    warn "sin clave GPG ni git config; copia config/zsh/zshrc.local.example a $ZSHRC_LOCAL y rellénala"
    return 1
  fi

  log "escribiendo identidad de packaging en $ZSHRC_LOCAL"
  {
    printf 'export DEBFULLNAME="%s"\n' "$nombre"
    printf 'export DEBEMAIL="%s"\n' "$correo"
  } >>"$ZSHRC_LOCAL"

  ok "identidad de packaging: $nombre <$correo>"
}

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

sbuild_tarball() {
  printf '%s/%s-%s.tar.zst' "$SBUILD_CACHE" "$SBUILD_SUITE" "$(dpkg --print-architecture)"
}

crear_chroot_sbuild() {
  local modo="$1" tarball
  tarball="$(sbuild_tarball)"

  if [[ "$modo" == conservar_existente && -f "$tarball" ]]; then
    ok "chroot de sbuild ya existe: $tarball"
    return 0
  fi

  mkdir -p "$SBUILD_CACHE"

  log "creando chroot ${SBUILD_SUITE}/$(dpkg --print-architecture) (tarda unos minutos)..."
  if ! mmdebstrap --variant=buildd "$SBUILD_SUITE" "${tarball}.nuevo" "$SBUILD_MIRROR"; then
    rm -f "${tarball}.nuevo"
    warn "mmdebstrap falló; el chroot no se tocó"
    return 1
  fi

  mv "${tarball}.nuevo" "$tarball"
  ok "chroot listo: $tarball"
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

  crear_chroot_sbuild conservar_existente
}
