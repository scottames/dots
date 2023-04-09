#!/bin/env zsh

# op
_OP_PLUGINS="${HOME}/.config/op/plugins.sh"
if [[ -f "${_OP_PLUGINS}" ]]; then
  source "${_OP_PLUGINS}"
fi

# direnv
if [[ $(command -v direnv) ]]; then
  eval "$(direnv hook zsh)"
fi

# zoxide | https://github.com/ajeetdsouza/zoxide
if [[ $(command -v zoxide) ]]; then
  eval "$(zoxide init zsh)"
fi

# gobrew
GOBREW_DIR="${HOME}/.gobrew"
GOBREW_BIN_DIR="${GOBREW_DIR}/bin"
if [[ ! -f "${GOBREW_BIN_DIR}/gobrew" ]]; then
  print_info "gobrew not found ${ARROW_RIGHT} installing${ELLIPSIS}"
  mkdir -p "${GOBREW_BIN_DIR}"
  [[ $IS_MAC -eq true ]] && GOBREW_ARCH_BIN="gobrew-darwin-64"
  [[ $IS_LINUX -eq true ]] && GOBREW_ARCH_BIN="gobrew-linux-64"
  curl -kLs "https://raw.githubusercontent.com/kevincobain2000/gobrew/master/bin/${GOBREW_ARCH_BIN}" \
    -o "${GOBREW_BIN_DIR}/gobrew"
  chmod +x "${GOBREW_BIN_DIR}/gobrew"
fi
[[ -d "${GOBREW_BIN_DIR}" ]] && PATH="${GOBREW_BIN_DIR}:${PATH}"
[[ -d "${GOBREW_BIN_DIR}/current/bin" ]] && PATH="${GOBREW_DIR}/current/bin:${PATH}"

# pyenv

if [[ -d "${HOME}/.pyenv" ]]; then
  export PYENV_ROOT="${HOME}/.pyenv"
  export PATH="${PYENV_ROOT}/bin:${PATH}"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  if [[ -d "${PYENV_ROOT}/plugins/pyenv-virtualenv" ]]; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

if [[ ! -d "${HOME}/.pyenv" ]]; then
  print_info "pyenv not found ${ARROW_RIGHT} installing${ELLIPSIS}"
  [[ $(command -v git) ]] \
    && ( git clone https://github.com/pyenv/pyenv.git ~/.pyenv \
      && git clone https://github.com/pyenv/pyenv-virtualenv.git \
    ~/.pyenv/plugins/pyenv-virtualenv ) \
    || print_info "Missing package: git${ELLIPSIS}"
  print_info "** reload of shell required**"
elif [[ ! $(command -v pyenv) ]] && [[ -d "${HOME}/.pyenv" ]]; then
  print_err "pyenv not found, but dir '${HOME}/.pyenv' found."
fi

if [[ ! $(command -v cht.sh) ]]; then
  print_info "cht.sh not found ${ARROW_RIGHT} installing${ELLIPSIS}"
  curl -fsSL -o "${HOME}/.local/bin/cht.sh" https://cht.sh/:cht.sh
  chmod +x "${HOME}/.local/bin/cht.sh"
fi
