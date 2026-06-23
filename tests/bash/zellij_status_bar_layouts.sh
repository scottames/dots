#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

assert_contains() {
  local actual="${1}"
  local expected="${2}"
  local message="${3}"

  if [[ ${actual} != *"${expected}"* ]]; then
    printf 'ASSERTION FAILED: %s\nexpected to contain: %s\nactual:\n%s\n' \
      "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_not_contains() {
  local actual="${1}"
  local unexpected="${2}"
  local message="${3}"

  if [[ ${actual} == *"${unexpected}"* ]]; then
    printf 'ASSERTION FAILED: %s\nunexpected: %s\nactual:\n%s\n' \
      "${message}" "${unexpected}" "${actual}" >&2
    exit 1
  fi
}

assert_layout_uses_status_bar() {
  local template="${1}"
  local rendered

  rendered="$(chezmoi execute-template <"${repo_root}/${template}")"

  assert_contains \
    "${rendered}" \
    'plugin location="status-bar"' \
    "${template} uses built-in status bar"
  assert_not_contains \
    "${rendered}" \
    'zellij-status' \
    "${template} does not use retired zellij-status plugin"
}

assert_layout_uses_status_bar 'home/private_dot_config/zellij/layouts/default.kdl.tmpl'
assert_layout_uses_status_bar 'home/private_dot_config/zellij/layouts/split-edit.kdl.tmpl'

printf 'ok\n'
