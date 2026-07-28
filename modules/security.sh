#!/usr/bin/env bash
# modules/security.sh

security_apt() {
  log "instalando herramientas de seguridad (apt)..."
  apt_install_list "${REPO_DIR}/packages/security.txt"
  ok "herramientas apt instaladas"
}

security_go() {
  log "instalando herramientas de Go..."

  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$PATH:$GOPATH/bin"

  local -A gotools=(
    [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    [httpx]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
    [nuclei]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    [naabu]="github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    [dnsx]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    [katana]="github.com/projectdiscovery/katana/cmd/katana@latest"
    [gau]="github.com/lc/gau/v2/cmd/gau@latest"
    [anew]="github.com/tomnomnom/anew@latest"
  )

  local tool
  for tool in "${!gotools[@]}"; do
    if [[ -x "${GOPATH}/bin/${tool}" ]]; then
      ok "ya instalado: $tool"
    else
      log "go install: $tool"
      go install "${gotools[$tool]}" && ok "instalado: $tool" \
        || warn "falló: $tool"
    fi
  done
}

security_pipx() {
  log "instalando herramientas de Python (pipx)..."

  local pytools=(
    arjun
    dirsearch
    wafw00f
    uro
  )

  local installed
  installed="$(pipx list 2>/dev/null)"

  local tool
  for tool in "${pytools[@]}"; do
    if grep -qi "package $tool " <<< "$installed"; then
      ok "ya instalado: $tool"
    else
      log "pipx install: $tool"
      pipx install "$tool" && ok "instalado: $tool" || warn "falló: $tool"
    fi
  done
}

install_security() {
  security_apt
  security_go
  security_pipx
  ok "capa de seguridad completada"
}

