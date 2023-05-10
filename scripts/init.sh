#!/bin/sh

set -e

magenta='\033[0;35m'
red='\033[0;31m'
yellow='\033[0;33m'
clear='\033[0m'

err() {
  printf "💥 ${red}%s${clear}\n" "${@}"
  exit 1
}

if [ -x "$(command -v distrobox)" ]; then
  if [ -x "$(command -v docker)" ] || [ -x "$(command -v podman)" ]; then
    err "distrobox found. init from distrobox instead."
  fi
fi

if [ ! -x "$(command -v curl)" ]; then
  err "curl required, but not found."
fi
if [ ! -x "$(command -v git)" ]; then
  err "git required, but not found."
fi
if [ ! -x "$(command -v go)" ]; then
  err "go required, but not found."
fi

if ! command -v chezmoi; then
  _bin_dir="${HOME}/.local/bin"
  _chezmoi="${_bin_dir}/chezmoi"
  if command -v curl; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "${_bin_dir}"
  elif command -v wget; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "${_bin_dir}"
  else
    err "To install chezmoi, you must have curl or wget installed."
  fi
else
  _chezmoi=chezmoi
fi

_CHEZMOI_SOURCE="scottames/dots"
_CHEZMOI_SOURCE_DIR="${HOME}/src/${_CHEZMOI_SOURCE}"

printf "\n${yellow}⚡ ${magenta}init chezmoi from ${clear}%s${magenta} to ${clear}%s\n\n" \
  "${_CHEZMOI_SOURCE}" "${_CHEZMOI_SOURCE_DIR}"

# exec: replace current process with chezmoi init
exec "${_chezmoi}" init --apply "${_CHEZMOI_SOURCE}" "--source=${_CHEZMOI_SOURCE_DIR}" "${@}"
