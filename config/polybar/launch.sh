#!/usr/bin/env bash
set -uo pipefail

CONFIG="$HOME/.config/polybar/config.ini"
LOG="${XDG_RUNTIME_DIR:-/tmp}/polybar.log"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"

# i3 (exec_always) y autorandr (postswitch) pueden llamar a este script a la
# vez tras un cambio de layout. Sin cerrojo se solapan los killall y quedan
# barras duplicadas o ninguna.
exec 9>"$LOCK"
# -w: si el cerrojo no llega, se sigue igualmente. Colgarse aqui dejaria la
# sesion sin barras, que es peor que un relanzamiento solapado.
flock -w 5 9 || true

# A polybar se le pregunta por los monitores en vez de parsear xrandr: es la
# misma lista que resuelven las barras, asi que no se lanza una barra contra
# una salida que el servidor todavia no ha activado.
monitors() {
  polybar --list-monitors 2>/dev/null | sed 's/:.*//'
}

primary_monitor() {
  polybar --list-monitors 2>/dev/null | awk '/\(primary\)/ {sub(/:.*/, ""); print; exit}'
}

# Tras un cambio de layout las salidas tardan un instante en aparecer.
for _ in $(seq 10); do
  [ -n "$(monitors)" ] && break
  sleep 0.2
done

killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

: > "$LOG"

launch_bar() {
  # Solo la pantalla primaria lleva la barra `main` (la que trae bandeja):
  # el systray es una seleccion X unica y una segunda barra que la pida
  # muere entera. El resto usa `aux`, identica pero sin bandeja.
  local monitor="$1" bar="$2"
  MONITOR="$monitor" polybar --reload "$bar" --config="$CONFIG" >>"$LOG" 2>&1 9>&- &
  disown
}

mapfile -t MONITORS < <(monitors)

if [ "${#MONITORS[@]}" -eq 0 ]; then
  polybar --reload main --config="$CONFIG" >>"$LOG" 2>&1 9>&- &
  disown
  exit 0
fi

PRIMARY="$(primary_monitor)"
[ -n "$PRIMARY" ] || PRIMARY="${MONITORS[0]}"

for monitor in "${MONITORS[@]}"; do
  if [ "$monitor" = "$PRIMARY" ]; then
    launch_bar "$monitor" main
  else
    launch_bar "$monitor" aux
  fi
done
