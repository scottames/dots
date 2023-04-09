#!/usr/bin/env zsh

[[ -d "${HOME}/src/bin" ]] && PATH=${PATH}:${HOME}/src/bin
[[ -d "${HOME}/bin" ]] && PATH=${PATH}:${HOME}/bin
[[ -d "${HOME}/.local/bin" ]] && PATH=${PATH}:${HOME}/.local/bin

if [[ $IS_MAC -eq true ]]; then

  # Put Homebrew at the head of the path
  # /usr/local/bin is also first in /etc/paths
  PATH=/usr/local/bin:${PATH}
  ## node bin
  PATH=${PATH}:${HOME}/.node/bin
  PATH=${PATH}:/usr/bin
  PATH=${PATH}:/bin
  PATH=${PATH}:/usr/sbin
  PATH=${PATH}:/sbin
  PATH=${PATH}:/opt/X11/bin
  PATH=${PATH}:/usr/local/heroku/bin
  PATH=${PATH}:/usr/local/MacGPG2/bin
  PATH=${PATH}:/usr/local/sbin
  PATH=${PATH}:/usr/local/heroku/bin
  PATH=${PATH}:/usr/local/packer

elif [[ $IS_LINUX -eq true ]]; then
  PATH=${PATH}:/usr/local/bin
  PATH=${PATH}:/usr/bin
  PATH=${PATH}:/usr/local/sbin
  PATH=${PATH}:/usr/sbin
  [[ -d /usr/local/heroku/bin ]] && PATH=${PATH}:/usr/local/heroku/bin
  [[ -d /usr/local/packer ]] && PATH=${PATH}:/usr/local/packer
  # manual tmux install (libevent typically installed here)
  if ! $(echo $LD_LIBRARY_PATH | grep -q /usr/local/lib); then
    if [[ -d /usr/local/lib ]]; then
      export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
    fi
  fi
fi

[[ -d "/var/lib/snapd/snap/bin" ]] && PATH="${PATH}:/var/lib/snapd/snap/bin"

[[ $(command -v dyff) ]] && export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
[[ -d "${KREW_ROOT}/bin" ]] && PATH="${PATH}:${KREW_ROOT}/bin"

export PATH="${HOME}/.cargo/bin:${PATH}"

[[ -d ${GOPATH}/bin ]] && PATH=${GOPATH}/bin:${PATH}
export GOPRIVATE="github.com/scottames/*"

[[ -d "${HOME}/.pyenv/shims" ]] && PATH="${HOME}/.pyenv/shims:${PATH}"

[[ -d "${AQUA_ROOT_DIR}" ]] && PATH="${AQUA_ROOT_DIR}:${PATH}"         # aqua
[[ -d "${AQUA_ROOT_DIR}/bin" ]] && PATH="${AQUA_ROOT_DIR}/bin:${PATH}" # aqua bins
[[ -f "${AQUA_CONFIG_DIR}/policy.yaml" ]] && \
  export AQUA_POLICY_CONFIG="${AQUA_CONFIG_DIR}/policy.yaml"

# export it!
export PATH=${PATH}

# remove duplicate entries
typeset -U PATH
