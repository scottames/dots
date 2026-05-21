#!/usr/bin/env bash

set -euo pipefail

voxtype_bin="${HOME}/.local/bin/voxtype"

hide_module() {
  printf '{"text":"","class":"stopped","tooltip":"Voxtype unavailable"}\n'
}

if ! command test -x "${voxtype_bin}"; then
  hide_module
  exit 0
fi

if ! systemctl --user --quiet is-active voxtype.service; then
  hide_module
  exit 0
fi

exec "${voxtype_bin}" status --follow --format json --extended --icon-theme nerd-font
