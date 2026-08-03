#!/usr/bin/env bash
set -uo pipefail

CONFIG="$HOME/.config/polybar/config.ini"
LOG="${XDG_RUNTIME_DIR:-/tmp}/polybar.log"

killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

: > "$LOG"

launch_bar() {
  MONITOR="$1" polybar --reload main --config="$CONFIG" >>"$LOG" 2>&1 &
  disown
}

connected_monitors() {
  xrandr --query | awk '/ connected/ {print $1}'
}

if command -v xrandr >/dev/null 2>&1; then
  while read -r monitor; do
    launch_bar "$monitor"
  done < <(connected_monitors)
else
  polybar --reload main --config="$CONFIG" >>"$LOG" 2>&1 &
  disown
fi
