#!/usr/bin/env bash
# Ensure mise lockfile symlink is correct.
#
# Usage: _ensure_mise_lockfile_symlink.sh <dots_dir>
#
# Mise v2026.2.0+ uses atomic writes for lockfiles which breaks symlinks.
# This script detects when mise replaces the symlink with a regular file
# and restores the symlink, syncing content back to the repo if needed.
#
# See: https://github.com/jdx/mise/pull/7927

set -eufo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <dots_dir>" >&2
  exit 1
fi

DOTS_DIR="$1"
MISE_LOCK_FILE="${HOME}/.config/mise/mise.lock"
MISE_LOCK_TARGET="${DOTS_DIR}/mise/mise.lock"
MISE_LOCK_TARGET_DIR="$(dirname "${MISE_LOCK_TARGET}")"

# colors
red='\033[0;31m'
# green='\033[0;32m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
# yellow='\033[0;33m'
clear='\033[0m'

# prints
print_info() { printf "${blue}🔗 ${magenta}%s${clear}\n" "${@}"; }
print_success() { printf "${cyan}🔗 %s${clear}\n" "${@}"; }
print_err() { printf "${red}🔗💥 %s${clear}\n\n" "${@}"; }
# print_warn() { printf "\n${yellow}⚠  %s${clear}\n\n" "${@}"; }

# Create/restore the symlink
_ensure_symlink() {
  mkdir -p "$(dirname "${MISE_LOCK_FILE}")"
  ln -sf "${MISE_LOCK_TARGET}" "${MISE_LOCK_FILE}"
  print_success "  linked:"
  print_success "   ${MISE_LOCK_FILE} -> ${MISE_LOCK_TARGET}"
}

printf "\n"

# Ensure target directory exists
if [[ ! -d ${MISE_LOCK_TARGET_DIR} ]]; then
  print_err "mise lock target directory does not exist: ${MISE_LOCK_TARGET_DIR}" >&2
  exit 1
fi

# Check if the mise.lock exists and is NOT a symlink (i.e., mise replaced it)
if [[ -f ${MISE_LOCK_FILE} && ! -L ${MISE_LOCK_FILE} ]]; then
  print_info "mise lockfile symlink was replaced with a regular file"
  print_info "  syncing content back to repo and restoring symlink..."

  # Sync content back to the repo (preserving mise's changes)
  if [[ -f ${MISE_LOCK_TARGET} ]]; then
    # Check if content differs
    if ! cmp -s "${MISE_LOCK_FILE}" "${MISE_LOCK_TARGET}"; then
      print_info "    content differs, updating repo copy..."
      cp "${MISE_LOCK_FILE}" "${MISE_LOCK_TARGET}"
    else
      print_info "    content unchanged, skipping copy"
    fi
  else
    print_info "    creating new lockfile in repo..."
    cp "${MISE_LOCK_FILE}" "${MISE_LOCK_TARGET}"
  fi

  # Remove the regular file and restore symlink
  _ensure_symlink

elif [[ -L ${MISE_LOCK_FILE} ]]; then
  # Symlink exists, verify it points to the right place
  current_target="$(readlink "${MISE_LOCK_FILE}")"
  if [[ ${current_target} != "${MISE_LOCK_TARGET}" ]]; then
    print_info "mise lockfile symlink points to wrong target: ${current_target}" >&2
    print_info "  expected: ${MISE_LOCK_TARGET}" >&2
    print_info "  fixing..."
    _ensure_symlink
  fi
  # Symlink is correct, nothing to do

elif [[ ! -e ${MISE_LOCK_FILE} ]]; then
  # No file exists, create the symlink if target exists
  if [[ -f ${MISE_LOCK_TARGET} ]]; then
    print_info "creating mise lockfile symlink..."
    _ensure_symlink
  fi
fi

# vi: ft=bash
