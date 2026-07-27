#!/usr/bin/env bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.2; done

if type xrandr >/dev/null 2>&1; then
	for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
		MONITOR=$m polybar --reload main --config="$HOME/.config/polybar/config.ini" 2>&1 | tee -a /tmp/polybar.log & disown
	done
else
	polybar --reload main --config="$HOME/.config/polybar/config.ini" main 2>&1 | tee -a /tmp/polybar.log & disown
fi
