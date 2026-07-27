#!/usr/bin/env bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.2; done
polybar --config="$HOME/.config/polybar/config.ini" main 2>&1 | tee -a /tmp/polybar.log & disown
