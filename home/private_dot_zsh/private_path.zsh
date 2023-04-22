#!/usr/bin/env zsh

_ps=(
  "${HOME}/src/bin"
  "${HOME}/bin"
  "${HOME}/.local/bin"
  "${GOPATH}/bin"
  "${HOME}/.cargo/bin"
  "${HOME}/.node/bin"
  "${KREW_ROOT}/bin"
  "${HOME}/.pyenv/shims"

  /usr/local/bin
  /usr/local/sbin
  /usr/local/heroku/bin
  /usr/local/packer

  /var/lib/snapd/snap/bin

  /usr/local/MacGPG2/bin
)

if $HAS_AQUA; then
  _ps+=(
    "${AQUA_ROOT_DIR}"
    "${AQUA_ROOT_DIR}/bin"
  )
fi

for _p in $_ps; do
  [[ -d "${_p}" ]] && path+=("${_p}")
done

export PATH
