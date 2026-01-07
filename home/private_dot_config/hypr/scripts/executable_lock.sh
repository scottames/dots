#!/usr/bin/env bash

printf "[LOG] launching hyprlock\n"
pidof hyprlock || hyprlock

if command -v 1password >/dev/null; then
  printf "[LOG] locking 1password\n"
  1password --lock || true
fi
