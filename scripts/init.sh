#!/bin/sh

set -e

magenta='\033[0;35m'
red='\033[0;31m'
yellow='\033[0;33m'
clear='\033[0m'

info() {
  printf "ℹ️ ${magenta}%s${clear}\n" "${@}"
}
err() {
  printf "💥 ${red}%s${clear}\n" "${@}"
  exit 1
}

install_gobrew() {
  info "no go found, attempting to install via gobrew"
  curl -sL https://raw.githubusercontent.com/kevincobain2000/gobrew/master/git.io.sh | sh

  export PATH="${HOME}/.gobrew/current/bin:${HOME}/.gobrew/bin:${PATH}"
  export GOROOT="${HOME}/.gobrew/current/go"

  "${HOME}"/.gobrew/bin/gobrew install latest

  if [ ! -x "$(command -v go)" ]; then
    err "go not found after attempting to install with gobrew."
  else
    info "go installed via gobrew! if gobrew intended to be used via aqua, run: rm -rf ~/.gobrew/bin"
  fi
}

if [ -x "$(command -v distrobox)" ]; then
  if [ -x "$(command -v docker)" ] || [ -x "$(command -v podman)" ]; then
    err "distrobox found. init from distrobox instead.

    distrobox create --image ghcr.io/scottames/fedora-toolbox:latest --name f

alternatively, arch: (may cause oddities with python install, etc. on fedora system)

    distrobox create --image ghcr.io/scottames/arch-toolbox:latest --name a
"
  fi
fi

if [ ! -x "$(command -v curl)" ]; then
  err "curl required, but not found."
fi
if [ ! -x "$(command -v git)" ]; then
  err "git required, but not found."
fi
if [ ! -x "$(command -v go)" ]; then
  install_gobrew
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

GIT_WORKTREES="${GIT_WORKTREES:-true}"

_CHEZMOI_SOURCE="scottames/dots"
if [ "${GIT_WORKTREES}" = true ]; then
  _CHEZMOI_SOURCE_DIR="${HOME}/src/github.com/${_CHEZMOI_SOURCE}/main"
else
  _CHEZMOI_SOURCE_DIR="${HOME}/src/github.com/${_CHEZMOI_SOURCE}"
fi

printf "\n${yellow}⚡ ${magenta}init chezmoi from ${clear}%s${magenta} to ${clear}%s\n  ${magenta}with args:${clear} " \
  "${_CHEZMOI_SOURCE}" "${_CHEZMOI_SOURCE_DIR}"
printf "%s " "${@}"
printf "\n\n"

# exec: replace current process with chezmoi init
exec "${_chezmoi}" init --apply "${_CHEZMOI_SOURCE}" "--source=${_CHEZMOI_SOURCE_DIR}" "${@}"
