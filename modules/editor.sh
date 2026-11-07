#!/usr/bin/env bash

# Neovim no sale de apt a proposito. Trixie congela 0.10.4 y telescope pide
# >0.10.4; ademas la API de LSP que usa config/nvim (vim.lsp.config y
# vim.lsp.enable) es de 0.11 en adelante. Se instala el tarball oficial en
# ~/.local, sin tocar el sistema y sin pelearse con dpkg.
NVIM_VERSION="v0.12.5"
NVIM_PREFIX="${HOME}/.local/nvim"
NVIM_BIN="${HOME}/.local/bin/nvim"
NVIM_CONFIG_DIR="${HOME}/.config/nvim"

nvim_arch() {
  case "$(uname -m)" in
    x86_64)          printf 'x86_64' ;;
    aarch64|arm64)   printf 'arm64' ;;
    *)               return 1 ;;
  esac
}

nvim_tarball_url() {
  local arch
  arch="$(nvim_arch)" || return 1
  printf 'https://github.com/neovim/neovim/releases/download/%s/nvim-linux-%s.tar.gz' \
    "$NVIM_VERSION" "$arch"
}

# "v0.12.5" a partir de la primera linea de `nvim --version`
nvim_version_instalada() {
  local binario="$1"
  [[ -x "$binario" ]] || return 1
  "$binario" --version 2>/dev/null | awk 'NR == 1 { print $2; exit }'
}

nvim_al_dia() {
  [[ "$(nvim_version_instalada "$NVIM_BIN" || true)" == "$NVIM_VERSION" ]]
}

instalar_neovim() {
  local modo="$1" url destino temporal arch
  destino="${NVIM_PREFIX}/${NVIM_VERSION}"

  if [[ "$modo" == conservar_existente ]] && nvim_al_dia; then
    ok "neovim ${NVIM_VERSION} ya instalado"
    return 0
  fi

  if ! arch="$(nvim_arch)"; then
    warn "arquitectura no soportada por los tarballs de neovim: $(uname -m)"
    return 1
  fi

  url="$(nvim_tarball_url)"
  temporal="$(mktemp -d)" || { warn "no pude crear el directorio temporal"; return 1; }

  log "descargando neovim ${NVIM_VERSION} (${arch})..."
  if ! curl -fsSL --retry 3 --retry-delay 2 "$url" -o "${temporal}/nvim.tar.gz"; then
    rm -rf "$temporal"
    warn "no pude descargar $url"
    return 1
  fi

  # El tarball trae un unico directorio raiz (nvim-linux-<arch>/) con
  # bin/, lib/ y share/. Se aplana con --strip-components=1.
  mkdir -p "${temporal}/nvim"
  if ! tar -xzf "${temporal}/nvim.tar.gz" -C "${temporal}/nvim" --strip-components=1; then
    rm -rf "$temporal"
    warn "el tarball de neovim no se pudo extraer"
    return 1
  fi

  if [[ ! -x "${temporal}/nvim/bin/nvim" ]]; then
    rm -rf "$temporal"
    warn "el tarball no contiene bin/nvim; upstream cambio el formato"
    return 1
  fi

  mkdir -p "$NVIM_PREFIX" "$(dirname "$NVIM_BIN")"
  rm -rf "$destino"
  mv "${temporal}/nvim" "$destino"
  rm -rf "$temporal"

  ln -sfn "${destino}/bin/nvim" "$NVIM_BIN"

  # Las versiones viejas solo ocupan; la actual es la unica que se enlaza.
  local antigua
  for antigua in "$NVIM_PREFIX"/*; do
    [[ -d "$antigua" && "$antigua" != "$destino" ]] || continue
    rm -rf "$antigua"
    ok "retirada version antigua: $(basename "$antigua")"
  done

  ok "neovim $(nvim_version_instalada "$NVIM_BIN") en $(ruta_corta "$NVIM_BIN")"
}

editor_neovim() {
  instalar_neovim conservar_existente
}

editor_deps() {
  log "instalando las dependencias de neovim..."
  apt_install_list "${REPO_DIR}/packages/nvim.txt"
  ok "dependencias de neovim instaladas"
}

editor_link_config() {
  # Se enlaza el directorio entero, no fichero a fichero: lazy.nvim escribe
  # lazy-lock.json dentro, y asi el lockfile cae en el repo y queda versionado.
  link_config nvim "$NVIM_CONFIG_DIR"
}

# lazy.nvim se instala solo en el primer arranque (bootstrap en init.lua).
# Aqui se fuerza sin abrir la interfaz, para que --dev deje el editor usable
# en vez de descargar medio ecosistema la primera vez que abres un fichero.
editor_plugins() {
  if [[ ! -x "$NVIM_BIN" ]]; then
    warn "neovim no esta instalado; omito la sincronizacion de plugins"
    return 1
  fi

  if [[ ! -e "${NVIM_CONFIG_DIR}/init.lua" ]]; then
    warn "no hay config en $(ruta_corta "$NVIM_CONFIG_DIR"); omito los plugins"
    return 1
  fi

  log "sincronizando los plugins de neovim (lazy.nvim)..."
  if ! "$NVIM_BIN" --headless "+Lazy! sync" +qa 2>&1 | tail -n 5; then
    warn "lazy.nvim fallo; abre nvim y ejecuta :Lazy sync a mano"
    return 1
  fi

  ok "plugins sincronizados; el lockfile vive en config/nvim/lazy-lock.json"
}
