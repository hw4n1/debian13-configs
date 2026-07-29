#!/usr/bin/env bash
# Muestra la IP de una interfaz tun. Con --next, avanza a la siguiente (ciclo).

STATE="/tmp/polybar-vpn-index"

# Lista de interfaces tun activas, ordenadas (tun0, tun1, ...)
mapfile -t tuns < <(ip -o -4 addr show 2>/dev/null | grep -oP '^\d+:\s+\Ktun\d+' | sort -u)

if [[ ${#tuns[@]} -eq 0 ]]; then
  echo "off"
  rm -f "$STATE"
  exit 0
fi

idx=0
[[ -f "$STATE" ]] && idx=$(<"$STATE")

if [[ "$1" == "--next" ]]; then
  idx=$(( (idx + 1) % ${#tuns[@]} ))
  echo "$idx" > "$STATE"
fi

(( idx >= ${#tuns[@]} )) && idx=0

iface="${tuns[$idx]}"
ip=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+')

if [[ ${#tuns[@]} -gt 1 ]]; then
  echo "${iface} ${ip:-off}"
else
  echo "${ip:-off}"
fi