#!/usr/bin/env bash

update_go_tools() {
  go_disponible || return 1
  log "actualizando herramientas de Go..."
  instalar_go_tools reinstalar_todo
}

update_pipx_tools() {
  if ! command -v pipx >/dev/null 2>&1; then
    warn "pipx no está instalado; omito las herramientas de Python"
    return 1
  fi

  log "actualizando herramientas de pipx..."
  pipx upgrade-all --include-injected
}

update_nuclei_templates() {
  if ! command -v nuclei >/dev/null 2>&1; then
    warn "nuclei no está instalado; omito sus plantillas"
    return 1
  fi

  log "actualizando plantillas de nuclei..."
  nuclei -update-templates -silent
  ok "plantillas en $(nuclei_templates_dir)"
}

update_seclists() {
  if [[ ! -d "${SECLISTS_DIR}/.git" ]]; then
    warn "$SECLISTS_DIR no es un clon de git; omito la actualización"
    return 1
  fi

  log "actualizando SecLists..."
  sudo git -C "$SECLISTS_DIR" pull --ff-only --quiet
  ok "SecLists actualizado"
}

update_gf_patterns() {
  command -v gf >/dev/null 2>&1 || { warn "gf no está instalado"; return 1; }
  log "actualizando patrones de gf..."
  copiar_patrones_gf sobrescribir
}

update_sbuild_chroot() {
  if ! command -v mmdebstrap >/dev/null 2>&1; then
    warn "falta mmdebstrap; no puedo recrear el chroot de sbuild"
    return 1
  fi

  log "recreando el chroot de ${SBUILD_SUITE}..."
  crear_chroot_sbuild recrear
}

run_update() {
  local fallidos=0

  update_go_tools          || fallidos=$((fallidos + 1))
  update_pipx_tools        || fallidos=$((fallidos + 1))
  update_nuclei_templates  || fallidos=$((fallidos + 1))
  update_gf_patterns       || fallidos=$((fallidos + 1))
  update_seclists          || fallidos=$((fallidos + 1))
  update_sbuild_chroot     || fallidos=$((fallidos + 1))

  if [[ $fallidos -gt 0 ]]; then
    warn "actualización terminada con $fallidos bloque(s) omitido(s)"
    return 1
  fi

  ok "todo actualizado"
}
