#!/usr/bin/env bash

declare -A GO_TOOLS=(
  [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  [httpx]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
  [nuclei]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
  [naabu]="github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
  [dnsx]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
  [katana]="github.com/projectdiscovery/katana/cmd/katana@latest"
  [gau]="github.com/lc/gau/v2/cmd/gau@latest"
  [anew]="github.com/tomnomnom/anew@latest"
  [gf]="github.com/tomnomnom/gf@latest"
  [qsreplace]="github.com/tomnomnom/qsreplace@latest"
  [assetfinder]="github.com/tomnomnom/assetfinder@latest"
  [dalfox]="github.com/hahwul/dalfox/v2@latest"
  [waybackurls]="github.com/tomnomnom/waybackurls@latest"
  [amass]="github.com/owasp-amass/amass/v4/...@master"
  [gowitness]="github.com/sensepost/gowitness@latest"
  [interactsh-client]="github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
  [notify]="github.com/projectdiscovery/notify/cmd/notify@latest"
  [greenclip]="github.com/erebe/greenclip@latest"
)

SECURITY_DOTFILES=(
  "bin/bb|.local/bin/bb"
)

declare -A PIPX_TOOLS=(
  [arjun]="arjun"
  [dirsearch]="dirsearch"
  [wafw00f]="wafw00f"
  [uro]="uro"
  [enum4linux-ng]="enum4linux-ng"
  [pwntools]="pwntools"
  [impacket]="impacket"
  [netexec]="git+https://github.com/Pennyw0rth/NetExec"
)

SECLISTS_DIR="/usr/share/seclists"
WORDLISTS_DIR="/usr/share/wordlists"
ROCKYOU_TAR="${SECLISTS_DIR}/Passwords/Leaked-Databases/rockyou.txt.tar.gz"

GF_PATTERNS_DIR="${HOME}/.gf"
GF_PATTERNS_REPOS=(
  "https://github.com/tomnomnom/gf"
  "https://github.com/1ndianl33t/Gf-Patterns"
)

NUCLEI_TEMPLATES_CONFIG="${HOME}/.config/nuclei/.templates-config.json"
SUBFINDER_PROVIDER_CONFIG="${HOME}/.config/subfinder/provider-config.yaml"

nuclei_templates_dir() {
  local ruta=""

  [[ -f "$NUCLEI_TEMPLATES_CONFIG" ]] \
    && ruta="$(sed -nE 's/.*"nuclei-templates-directory":"([^"]+)".*/\1/p' "$NUCLEI_TEMPLATES_CONFIG")"

  printf '%s' "${ruta:-${HOME}/nuclei-templates}"
}

subfinder_claves_configuradas() {
  [[ -f "$SUBFINDER_PROVIDER_CONFIG" ]] || { printf '0'; return 0; }

  grep -cvE '^[[:space:]]*(#|$)|:[[:space:]]*\[\][[:space:]]*$' \
    "$SUBFINDER_PROVIDER_CONFIG" || true
}

security_apt() {
  log "instalando herramientas de seguridad (apt)..."
  apt_install_list "${REPO_DIR}/packages/security.txt"
  ok "herramientas apt instaladas"
}

go_disponible() {
  command -v go >/dev/null 2>&1 && return 0
  warn "go no está instalado; omito las herramientas de Go"
  return 1
}

instalar_go_tools() {
  local modo="$1" nombre

  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$PATH:$GOPATH/bin"

  for nombre in "${!GO_TOOLS[@]}"; do
    if [[ "$modo" == omitir_existentes && -x "${GOPATH}/bin/${nombre}" ]]; then
      ok "ya instalado: $nombre"
      continue
    fi

    log "go install: $nombre"
    go install "${GO_TOOLS[$nombre]}" && ok "instalado: $nombre" || warn "falló: $nombre"
  done
}

security_go() {
  go_disponible || return 1
  log "instalando herramientas de Go..."
  instalar_go_tools omitir_existentes
}

pipx_installed() {
  pipx list --short 2>/dev/null | cut -d' ' -f1 | grep -qxF "$1"
}

security_pipx() {
  if ! command -v pipx >/dev/null 2>&1; then
    warn "pipx no está instalado; omito las herramientas de Python"
    return 1
  fi

  log "instalando herramientas de Python (pipx)..."

  local nombre
  for nombre in "${!PIPX_TOOLS[@]}"; do
    if pipx_installed "$nombre"; then
      ok "ya instalado: $nombre"
    else
      log "pipx install: $nombre"
      pipx install "${PIPX_TOOLS[$nombre]}" && ok "instalado: $nombre" || warn "falló: $nombre"
    fi
  done
}

security_docker() {
  log "configurando Docker..."

  if systemctl is-active --quiet docker; then
    ok "servicio docker ya activo"
  else
    sudo systemctl enable --now docker && ok "servicio docker activado"
  fi

  if id -nG "$USER" | grep -qw docker; then
    ok "usuario ya en el grupo docker"
  else
    sudo usermod -aG docker "$USER"
    warn "añadido al grupo docker (equivale a root): cierra sesión y vuelve a entrar"
  fi
}

security_wordlists() {
  if [[ -d "$SECLISTS_DIR" ]]; then
    ok "seclists ya presente"
    return 0
  fi

  log "clonando SecLists..."
  if sudo git clone --depth 1 https://github.com/danielmiessler/SecLists "$SECLISTS_DIR"; then
    ok "seclists instalado"
  else
    warn "falló seclists"
    return 1
  fi
}

gf_patterns_presentes() {
  compgen -G "${GF_PATTERNS_DIR}/*.json" >/dev/null 2>&1
}

copiar_patrones_gf() {
  local modo="$1" temporal repo opcion_copia="-n"
  [[ "$modo" == sobrescribir ]] && opcion_copia="-f"

  temporal="$(mktemp -d)"
  mkdir -p "$GF_PATTERNS_DIR"

  for repo in "${GF_PATTERNS_REPOS[@]}"; do
    git clone --depth 1 --quiet "$repo" "${temporal}/$(basename "$repo")" \
      || warn "falló el clonado de $repo"
  done

  find "$temporal" -name '*.json' -exec cp "$opcion_copia" {} "$GF_PATTERNS_DIR/" \;
  rm -rf "$temporal"

  if ! gf_patterns_presentes; then
    warn "no se copió ningún patrón de gf"
    return 1
  fi

  ok "patrones de gf: $(find "$GF_PATTERNS_DIR" -name '*.json' | wc -l)"
}

security_gf_patterns() {
  if ! command -v gf >/dev/null 2>&1; then
    warn "gf no está instalado; omito sus patrones"
    return 1
  fi

  if gf_patterns_presentes; then
    ok "patrones de gf ya presentes"
    return 0
  fi

  log "instalando patrones de gf..."
  copiar_patrones_gf conservar_existentes
}

security_rockyou() {
  local rockyou="${WORDLISTS_DIR}/rockyou.txt"

  if [[ -s "$rockyou" ]]; then
    ok "rockyou.txt ya disponible"
    return 0
  fi

  if [[ ! -f "$ROCKYOU_TAR" ]]; then
    warn "no encuentro $ROCKYOU_TAR; hace falta SecLists primero"
    return 1
  fi

  log "extrayendo rockyou.txt desde SecLists..."
  sudo mkdir -p "$WORDLISTS_DIR"

  if ! sudo tar -xzf "$ROCKYOU_TAR" -C "$WORDLISTS_DIR"; then
    warn "falló la extracción de rockyou.txt"
    return 1
  fi

  sudo ln -sfn "$SECLISTS_DIR" "${WORDLISTS_DIR}/seclists"
  ok "rockyou.txt disponible en $rockyou"
}

security_link_dotfiles() {
  log "enlazando herramientas propias..."

  local fallidos=0 entrada origen destino
  for entrada in "${SECURITY_DOTFILES[@]}"; do
    origen="${entrada%%|*}"
    destino="${entrada##*|}"
    link_config "$origen" "$HOME/$destino" || fallidos=$((fallidos + 1))
  done

  [[ $fallidos -eq 0 ]] || return 1
  ok "herramientas propias enlazadas"
}

install_security() {
  local fallidos=0

  security_apt           || fallidos=$((fallidos + 1))
  security_link_dotfiles || fallidos=$((fallidos + 1))
  security_go            || fallidos=$((fallidos + 1))
  security_pipx          || fallidos=$((fallidos + 1))
  security_docker        || fallidos=$((fallidos + 1))
  security_wordlists     || fallidos=$((fallidos + 1))
  security_rockyou       || fallidos=$((fallidos + 1))
  security_gf_patterns   || fallidos=$((fallidos + 1))

  if [[ $fallidos -gt 0 ]]; then
    warn "capa de seguridad completada con $fallidos bloque(s) omitido(s)"
    return 1
  fi

  ok "capa de seguridad completada"
}
