#!/usr/bin/env zsh

UNAME="$(uname)"

if [[ "${UNAME}" = "Linux" ]]; then
  export IS_LINUX=true
  if [[ "$(cat /proc/version | grep arch)" ]]; then
    export DISTRO="arch"
  elif [[ "$(cat /proc/version | grep Ubuntu)" ]]; then
    export DISTRO="ubuntu"
  fi
fi

if [[ "${UNAME}" = "Darwin" ]]; then
  export IS_MAC=true
fi

_bins=(
  apt
  bat
  brew
  dyff
  hub
  gh
  gum
  nvim
  op
  ugum
  vim
  virtualenv
  yum
  zplug
)

function _command_exists() {
  command -v "${1}" >/dev/null 2>&1
}

for _b in $_bins; do
  if _command_exists "${_b}"; then
    export "HAS_${_b:u}"=true
  else
    export "HAS_${_b:u}"=false
  fi
done
