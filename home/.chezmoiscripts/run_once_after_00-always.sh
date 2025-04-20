#!/usr/bin/env bash

yellow='\033[0;33m'
clear='\033[0m'

warn() {
  printf "${yellow}❕%s${clear}\n" "${@}"
}

if [ ! -x "$(command -v fish)" ]; then
  warn "fish not found."
fi
