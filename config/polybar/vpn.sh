#!/usr/bin/env bash
ip=$(ip -4 addr show tun0 2>/dev/null | grep -oP 'inet \K[\d.]+')
echo "${ip:-off}"
