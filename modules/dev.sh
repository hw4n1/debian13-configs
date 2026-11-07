#!/usr/bin/env bash

SBUILD_SUITE="unstable"
SBUILD_MIRROR="http://deb.debian.org/debian"
SBUILD_CACHE="${HOME}/.cache/sbuild"

DEV_DOTFILES=(
  "sbuild/config.pl|.config/sbuild/config.pl"
  "devscripts/quiltrc-dpkg|.quiltrc-dpkg"
  "devscripts/devscripts|.devscripts"
  "git/gitconfig|.gitconfig"
  "gbp/gbp.conf|.gbp.conf"
  "nvim|.config/nvim"
)

ZSHRC_LOCAL="${HOME}/.zshrc.local"
GITCONFIG_LOCAL="${HOME}/.gitconfig.local"

gpg_uid_primaria() {
  gpg --list-secret-keys --with-colons 2>/dev/null \
    | awk -F: '$1 == "uid" { print $10; exit }'
}

gpg_huella_primaria() {
  gpg --list-secret-keys --with-colons 2>/dev/null \
    | awk -F: '$1 == "fpr" { print $10; exit }'
}

nombre_de_uid() { sed -E 's/ *[(<].*//' <<<"$1"; }
correo_de_uid() { sed -nE 's/.*<([^>]+)>.*/\1/p' <<<"$1"; }

dev_identidad_git() {
  if [[ -f "$GITCONFIG_LOCAL" ]]; then
    ok "identidad de git ya definida en $(ruta_corta "$GITCONFIG_LOCAL")"
    return 0
  fi

  local uid nombre correo huella directorio
  uid="$(gpg_uid_primaria)"
  nombre="$(git config --get user.name || true)"
  correo="$(git config --get user.email || true)"
  huella="$(gpg_huella_primaria)"

  [[ -n "$nombre" ]] || nombre="$(nombre_de_uid "$uid")"
  [[ -n "$correo" ]] || correo="$(correo_de_uid "$uid")"

  if [[ -z "$nombre" || -z "$correo" ]]; then
    warn "sin identidad de git ni clave GPG; configura user.name y user.email antes"
    return 1
  fi

  log "escribiendo identidad de git en $GITCONFIG_LOCAL"
  {
    printf '[user]\n'
    printf '\tname = %s\n' "$nombre"
    printf '\temail = %s\n' "$correo"
    if [[ -n "$huella" ]]; then
      printf '\tsigningkey = %s\n' "$huella"
    fi

    while read -r directorio; do
      [[ -n "$directorio" ]] || continue
      printf '[safe]\n\tdirectory = %s\n' "$directorio"
    done < <(git config --get-all safe.directory || true)
  } >"$GITCONFIG_LOCAL"

  ok "identidad de git: $nombre <$correo>"
}

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

dev_kernel_deps() {
  log "instalando las dependencias de construccion del kernel..."
  apt_install_list "${REPO_DIR}/packages/kernel.txt"
  ok "dependencias del kernel instaladas"
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

SBUILDRC_OBSOLETO="${HOME}/.sbuildrc"

dev_retirar_sbuildrc_obsoleto() {
  [[ -L "$SBUILDRC_OBSOLETO" ]] || return 0
  [[ "$(readlink -f "$SBUILDRC_OBSOLETO")" == "${REPO_DIR}"/* ]] || return 0

  rm -f "$SBUILDRC_OBSOLETO"
  ok "retirado $(ruta_corta "$SBUILDRC_OBSOLETO"): lo gana ~/.config/sbuild/config.pl"
}

dev_link_dotfiles() {
  log "enlazando dotfiles de packaging..."
  dev_retirar_sbuildrc_obsoleto

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

sbuild_tarball_en_construccion() {
  printf '%s/%s-%s.nuevo.tar.zst' "$SBUILD_CACHE" "$SBUILD_SUITE" "$(dpkg --print-architecture)"
}

crear_chroot_sbuild() {
  local modo="$1" tarball temporal
  tarball="$(sbuild_tarball)"
  temporal="$(sbuild_tarball_en_construccion)"

  if [[ "$modo" == conservar_existente && -f "$tarball" ]]; then
    ok "chroot de sbuild ya existe: $tarball"
    return 0
  fi

  mkdir -p "$SBUILD_CACHE"
  rm -rf "$temporal"

  log "creando chroot ${SBUILD_SUITE}/$(dpkg --print-architecture) (tarda unos minutos)..."
  if ! mmdebstrap --variant=buildd --include=eatmydata \
       "$SBUILD_SUITE" "$temporal" "$SBUILD_MIRROR"; then
    rm -rf "$temporal"
    warn "mmdebstrap falló; el chroot anterior no se tocó"
    return 1
  fi

  mv "$temporal" "$tarball"
  ok "chroot listo: $tarball"
}

dev_sbuild_chroot() {
  if ! command -v mmdebstrap >/dev/null 2>&1; then
    warn "falta mmdebstrap; no puedo crear el chroot de sbuild"
    return 1
  fi

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
