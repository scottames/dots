#!/usr/bin/env bash

printf "[LOG] launching hyprlock\n"
pidof hyprlock || hyprlock

if command -v 1password >/dev/null && pidof 1password >/dev/null; then
  printf "[LOG] locking 1password\n"
  1password --lock || true
elif command -v 1password >/dev/null; then
  printf "[LOG] 1password not running; skipping lock\n"
fi
