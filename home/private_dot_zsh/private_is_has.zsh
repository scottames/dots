#!/usr/bin/env zsh

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

[[ "$(command -v apt-get)" ]]    && export HAS_APT=true
[[ "$(command -v bat)" ]]        && export HAS_BAT=true
[[ "$(command -v brew)" ]]       && export HAS_BREW=true
[[ "$(command -v dyff)" ]]       && export HAS_DYFF=true
[[ "$(command -v hub)" ]]        && export HAS_HUB=true
[[ "$(command -v nvim)" ]]       && export HAS_GH=true
[[ "$(command -v nvim)" ]]       && export HAS_NVIM=true
[[ "$(command -v op)" ]]         && export HAS_OP=true
[[ "$(command -v vim)" ]]        && export HAS_VIM=true
[[ "$(command -v virtualenv)" ]] && export HAS_VIRTUALENV=true
[[ "$(command -v yum)" ]]        && export HAS_YUM=true
[[ "$(command -v zplug)" ]]      && export HAS_ZPLUG=true
