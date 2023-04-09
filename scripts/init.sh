#!/bin/sh

set -e # -e: exit on error

_CHEZMOI_SOURCE="scottames/dots"
_CHEZMOI_SOURCE_DIR="${HOME}/src/${_CHEZMOI_SOURCE}"

if command -v chezmoi; then
  _bin_dir="${HOME}/.local/bin"
  _chezmoi="${_bin_dir}/chezmoi"
  if command -v curl; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "${_bin_dir}"
  elif command -v wget; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "${_bin_dir}"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
else
  _chezmoi=chezmoi
fi

# exec: replace current process with chezmoi init
exec "${_chezmoi}" init --apply "${_CHEZMOI_SOURCE}" "--source=${_CHEZMOI_SOURCE_DIR}"
