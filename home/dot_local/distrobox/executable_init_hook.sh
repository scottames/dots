#!/bin/env sh

if test -f "/etc/os-release"; then
  if grep -q Arch </etc/os-release; then
    printf "LANG=en_US.UTF-8\nLANGUAGE=en_US" | sudo tee /etc/locale.conf
    sudo sed -i '/\#en_US.UTF-8 UTF-8/{s/#//g;s/@/-at-/g;}' /etc/locale.gen
    sudo locale-gen
  elif grep -q Ubuntu </etc/os-release; then
    sudo locale-gen en_US
    sudo locale-gen en_US.UTF-8
    sudo update-locale
  fi
fi
