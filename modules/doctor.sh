#!/usr/bin/env bash

DOCTOR_FALLOS=0
DOCTOR_AVISOS=0

CHROOT_DIAS_MAXIMO=14
TEMPLATES_DIAS_MAXIMO=7

check_ok()   { printf '[ok]   %s\n' "$*"; }
check_warn() { printf '[warn] %s\n' "$*"; DOCTOR_AVISOS=$((DOCTOR_AVISOS + 1)); }
check_fail() { printf '[FALLA] %s\n' "$*"; DOCTOR_FALLOS=$((DOCTOR_FALLOS + 1)); }
check_skip() { printf '[n/a]  %s\n' "$*"; }

seccion() { printf '\n== %s ==\n' "$*"; }

dias_desde_modificacion() {
  local ruta="$1" ahora modificado
  ahora="$(date +%s)"
  modificado="$(stat -c %Y "$ruta" 2>/dev/null)" || return 1
  printf '%s' "$(( (ahora - modificado) / 86400 ))"
}

check_frescura() {
  local ruta="$1" maximo="$2" descripcion="$3" dias

  if [[ ! -e "$ruta" ]]; then
    check_fail "$descripcion: no existe ($ruta)"
    return
  fi

  dias="$(dias_desde_modificacion "$ruta")" || {
    check_warn "$descripcion: no puedo leer la fecha de $ruta"
    return
  }

  if [[ "$dias" -gt "$maximo" ]]; then
    check_warn "$descripcion: $dias días sin actualizar (máximo $maximo)"
  else
    check_ok "$descripcion: $dias días"
  fi
}

check_symlink() {
  local enlace="$1" origen_relativo="$2" origen
  origen="$(readlink -f "${REPO_DIR}/config/${origen_relativo}" 2>/dev/null)"

  if already_linked_to "$enlace" "$origen"; then
    check_ok "enlazado: $(ruta_corta "$enlace")"
  elif [[ -e "$enlace" ]]; then
    check_fail "$(ruta_corta "$enlace") existe pero no apunta al repo"
  else
    check_fail "$(ruta_corta "$enlace") no existe"
  fi
}

check_comando() {
  local comando="$1" pista="${2:-}"

  if command -v "$comando" >/dev/null 2>&1; then
    check_ok "comando: $comando"
  else
    check_fail "falta el comando $comando${pista:+ ($pista)}"
  fi
}

doctor_dotfiles() {
  seccion "Dotfiles"

  local entrada origen destino
  for entrada in "${DOTFILES[@]}" "${DEV_DOTFILES[@]}"; do
    origen="${entrada%%|*}"
    destino="${entrada##*|}"
    check_symlink "$HOME/$destino" "$origen"
  done
}

doctor_apt() {
  seccion "Fuentes de apt"

  local fuentes
  if ! fuentes="$(apt_sources_file)"; then
    check_fail "no encuentro un archivo de fuentes conocido"
    return
  fi

  check_ok "fuentes: $fuentes"

  if grep -q contrib "$fuentes"; then
    check_ok "contrib/non-free habilitados"
  else
    check_fail "contrib/non-free deshabilitados en $fuentes"
  fi

  local habilitado
  if apt_sources_is_deb822 "$fuentes"; then
    habilitado='^Types:.*[[:space:]]deb-src'
  else
    habilitado='^deb-src[[:space:]]'
  fi

  if grep -qE "$habilitado" "$fuentes"; then
    check_ok "deb-src habilitado"
  else
    check_fail "deb-src deshabilitado: 'apt source' no funcionará"
  fi
}

doctor_packaging() {
  seccion "Packaging Debian"

  if [[ ! -f "$ZSHRC_LOCAL" ]]; then
    check_fail "$ZSHRC_LOCAL no existe: dch firmará el changelog con un correo inventado"
  elif ! grep -q '^export DEBEMAIL=' "$ZSHRC_LOCAL"; then
    check_fail "$ZSHRC_LOCAL no define DEBEMAIL"
  else
    check_ok "identidad de packaging definida en $(ruta_corta "$ZSHRC_LOCAL")"
  fi

  if [[ -n "$(gpg_uid_primaria)" ]]; then
    check_ok "clave GPG secreta presente: $(gpg_uid_primaria)"
  else
    check_fail "sin clave GPG secreta: no puedes firmar subidas ni RFS"
  fi

  if [[ -f "$GITCONFIG_LOCAL" ]] && grep -q 'email' "$GITCONFIG_LOCAL"; then
    check_ok "identidad de git en $(ruta_corta "$GITCONFIG_LOCAL")"
  else
    check_fail "$GITCONFIG_LOCAL no define la identidad de git"
  fi

  if [[ -n "$(git config --get user.signingkey || true)" ]]; then
    check_ok "clave de firma de git configurada"
  else
    check_warn "git sin user.signingkey: no podrás firmar tags"
  fi

  if [[ -d "$CCACHE_DIR_SBUILD" ]]; then
    check_ok "ccache de sbuild en $(ruta_corta "$CCACHE_DIR_SBUILD")"
  else
    check_fail "falta $CCACHE_DIR_SBUILD: sbuild abortará al montar el bind de ccache"
  fi

  if grep -q "^${USER}:" /etc/subuid && grep -q "^${USER}:" /etc/subgid; then
    check_ok "rangos subuid/subgid asignados a $USER"
  else
    check_fail "faltan rangos subuid/subgid: el backend unshare de sbuild no arrancará"
  fi

  local arch tarball
  arch="$(dpkg --print-architecture)"
  tarball="${SBUILD_CACHE}/${SBUILD_SUITE}-${arch}.tar.zst"
  check_frescura "$tarball" "$CHROOT_DIAS_MAXIMO" "chroot de sbuild ($SBUILD_SUITE)"

  local comando
  for comando in sbuild mmdebstrap quilt dch debuild lintian piuparts autopkgtest; do
    check_comando "$comando" "./setup.sh --dev"
  done
}

doctor_seguridad() {
  seccion "Herramientas de seguridad"

  if ! command -v go >/dev/null 2>&1; then
    check_skip "go no instalado: omito las herramientas de Go"
  else
    local faltan_go=()
    local nombre
    for nombre in "${!GO_TOOLS[@]}"; do
      [[ -x "${GOPATH:-$HOME/go}/bin/${nombre}" ]] || faltan_go+=("$nombre")
    done

    if [[ ${#faltan_go[@]} -eq 0 ]]; then
      check_ok "herramientas de Go: ${#GO_TOOLS[@]}/${#GO_TOOLS[@]}"
    else
      check_fail "faltan herramientas de Go: ${faltan_go[*]}"
    fi
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    check_skip "pipx no instalado: omito las herramientas de Python"
  else
    local faltan_pipx=()
    local nombre
    for nombre in "${!PIPX_TOOLS[@]}"; do
      pipx_installed "$nombre" || faltan_pipx+=("$nombre")
    done

    if [[ ${#faltan_pipx[@]} -eq 0 ]]; then
      check_ok "herramientas de pipx: ${#PIPX_TOOLS[@]}/${#PIPX_TOOLS[@]}"
    else
      check_fail "faltan herramientas de pipx: ${faltan_pipx[*]}"
    fi
  fi

  if [[ -d "$SECLISTS_DIR" ]]; then
    check_ok "SecLists en $SECLISTS_DIR"
  else
    check_fail "SecLists ausente en $SECLISTS_DIR"
  fi

  if [[ -s "${WORDLISTS_DIR}/rockyou.txt" ]]; then
    check_ok "rockyou.txt disponible"
  else
    check_fail "falta ${WORDLISTS_DIR}/rockyou.txt: el cheatsheet lo da por hecho"
  fi

  if gf_patterns_presentes; then
    check_ok "patrones de gf: $(find "$GF_PATTERNS_DIR" -name '*.json' | wc -l)"
  else
    check_fail "gf sin patrones en $GF_PATTERNS_DIR: el binario no sirve de nada"
  fi

  check_frescura "$(nuclei_templates_dir)" "$TEMPLATES_DIAS_MAXIMO" "plantillas de nuclei"

  if [[ "$(subfinder_claves_configuradas)" -gt 0 ]]; then
    check_ok "subfinder: $(subfinder_claves_configuradas) proveedor(es) con clave"
  else
    check_warn "subfinder sin API keys: el recon pierde la mayor parte de la cobertura"
  fi

  check_comando bb "./setup.sh --security"

  if id -nG "$USER" | grep -qw docker; then
    check_ok "usuario en el grupo docker"
  else
    check_warn "usuario fuera del grupo docker: el alias kali pedirá sudo"
  fi
}

doctor_shell() {
  seccion "Shell y entorno"

  local zsh_bin
  zsh_bin="$(command -v zsh || true)"

  if [[ -n "$zsh_bin" && "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_bin" ]]; then
    check_ok "zsh es el shell por defecto"
  else
    check_warn "zsh no es el shell por defecto"
  fi

  if [[ -n "${EDITOR:-}" ]]; then
    check_ok "EDITOR=$EDITOR"
  else
    check_fail "EDITOR sin definir: dch, bts y reportbug abrirán un editor al azar"
  fi

  if fc-list 2>/dev/null | grep -qi "${NERD_FONT} Nerd Font"; then
    check_ok "${NERD_FONT} Nerd Font instalada"
  else
    check_warn "${NERD_FONT} Nerd Font ausente: polybar caerá a texto"
  fi
}

run_doctor() {
  log "revisando el estado de la máquina..."

  doctor_dotfiles
  doctor_apt
  doctor_shell
  doctor_packaging
  doctor_seguridad

  printf '\n'
  if [[ $DOCTOR_FALLOS -eq 0 && $DOCTOR_AVISOS -eq 0 ]]; then
    ok "todo en orden"
    return 0
  fi

  if [[ $DOCTOR_FALLOS -eq 0 ]]; then
    warn "$DOCTOR_AVISOS aviso(s), ningún fallo"
    return 0
  fi

  warn "$DOCTOR_FALLOS fallo(s) y $DOCTOR_AVISOS aviso(s)"
  return 1
}
