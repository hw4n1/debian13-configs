#!/usr/bin/env bash
set -uo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/polybar-vpn-index"

read_index() {
  local guardado
  [[ -f "$STATE" ]] || { printf '0'; return; }

  guardado="$(<"$STATE")"
  [[ "$guardado" =~ ^[0-9]+$ ]] || guardado=0
  printf '%s' "$guardado"
}

mapfile -t tuns < <(ip -o -4 addr show 2>/dev/null | grep -oP '^\d+:\s+\Ktun\d+' | sort -u)

if [[ ${#tuns[@]} -eq 0 ]]; then
  echo "off"
  rm -f "$STATE"
  exit 0
fi

idx="$(read_index)"

if [[ "${1:-}" == "--next" ]]; then
  idx=$(( (idx + 1) % ${#tuns[@]} ))
  echo "$idx" > "$STATE"
fi

(( idx >= ${#tuns[@]} )) && idx=0

iface="${tuns[$idx]}"
direccion="$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+')"

if [[ ${#tuns[@]} -gt 1 ]]; then
  echo "${iface} ${direccion:-off}"
else
  echo "${direccion:-off}"
fi
