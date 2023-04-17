#!/usr/bin/env zsh

export HAS_APT=false
export HAS_BAT=false
export HAS_BREW=false
export HAS_DYFF=false
export HAS_HUB=false
export HAS_GH=false
export HAS_NVIM=false
export HAS_OP=false
export HAS_VIM=false
export HAS_VIRTUALENV=false
export HAS_YUM=false
export HAS_ZPLUG=false
export IS_DOCKER=false
export IS_LINUX=false
export IS_MAC=false

if [[ $(uname) = 'Linux' ]]; then
  export IS_LINUX=true
  if [[ "$(cat /proc/version | grep arch)" ]]; then
    export DISTRO="arch"
  elif [[ "$(cat /proc/version | grep Ubuntu)" ]]; then
    export DISTRO="ubuntu"
  fi
fi

if [[ $(uname) = 'Darwin' ]]; then
  export IS_MAC=true
fi

[[ -x "$(command -v apt-get)" ]]   && export HAS_APT=true
[[ -x "$(command -v bat)" ]]       && export HAS_BAT=true
[[ -x "$(command -v brew)" ]]      && export HAS_BREW=true
[[ -x "$(command -v dyff)" ]]      && export HAS_DYFF=true
[[ -x "$(command -v hub)" ]]       && export HAS_HUB=true
[[ -x "$(command -v gh)" ]]        && export HAS_GH=true
[[ -x "$(command -v nvim)" ]]      && export HAS_NVIM=true
[[ -x "$(command -v op)" ]]        && export HAS_OP=true
[[ -x "$(command -v vim)" ]]       && export HAS_VIM=true
[[ -x "$(command -v virtualenv)" ]]&& export HAS_VIRTUALENV=true
[[ -x "$(command -v yum)" ]]       && export HAS_YUM=true
[[ -x "$(command -v zplug)" ]]     && export HAS_ZPLUG=true
