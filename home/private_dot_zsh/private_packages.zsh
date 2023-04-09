#!/usr/bin/env zsh

alias upgrade_cargo="cargo install --list | grep -v '^ ' | cut -d' ' -f 1 | xargs cargo install"
alias upgrade_rust="rustup update && cargo-update"

if [[ $IS_LINUX -eq true ]]; then
  case "${DISTRO}" in
    "arch")
      if [[ $(command -v paru) ]]; then
        alias update="paru -Syy"
        alias upgrade="paru -Syyu && upgrade_rust"
      else
        alias update="pacman -Syy"
        alias upgrade="print_warn 'no AUR updates will be performed' && sudo pacman -Syyu"
      fi
      ;;
    "ubuntu")
      alias upgrade="sudo apt update && sudo apt upgrade && sudo apt autoremove && upgrade_rust"
      alias update="sudo apt update"
      ;;
  esac
fi
