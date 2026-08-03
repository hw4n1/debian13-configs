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
  [greenclip]="github.com/erebe/greenclip@latest"
)

declare -A PIPX_TOOLS=(
  [arjun]="arjun"
  [dirsearch]="dirsearch"
  [wafw00f]="wafw00f"
  [uro]="uro"
  [enum4linux-ng]="enum4linux-ng"
  [pwntools]="pwntools"
  [netexec]="git+https://github.com/Pennyw0rth/NetExec"
)

SECLISTS_DIR="/usr/share/seclists"

security_apt() {
  log "instalando herramientas de seguridad (apt)..."
  apt_install_list "${REPO_DIR}/packages/security.txt"
  ok "herramientas apt instaladas"
}

security_go() {
  if ! command -v go >/dev/null 2>&1; then
    warn "go no está instalado; omito las herramientas de Go"
    return 1
  fi

  log "instalando herramientas de Go..."

  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$PATH:$GOPATH/bin"

  local nombre
  for nombre in "${!GO_TOOLS[@]}"; do
    if [[ -x "${GOPATH}/bin/${nombre}" ]]; then
      ok "ya instalado: $nombre"
    else
      log "go install: $nombre"
      go install "${GO_TOOLS[$nombre]}" && ok "instalado: $nombre" || warn "falló: $nombre"
    fi
  done
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

install_security() {
  local fallidos=0

  security_apt       || fallidos=$((fallidos + 1))
  security_go        || fallidos=$((fallidos + 1))
  security_pipx      || fallidos=$((fallidos + 1))
  security_docker    || fallidos=$((fallidos + 1))
  security_wordlists || fallidos=$((fallidos + 1))

  if [[ $fallidos -gt 0 ]]; then
    warn "capa de seguridad completada con $fallidos bloque(s) omitido(s)"
    return 1
  fi

  ok "capa de seguridad completada"
}
