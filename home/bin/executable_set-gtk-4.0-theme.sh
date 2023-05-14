#!/bin/env bash

set -e

_THEME_DIR="${1}"

if [[ -z ${_THEME_DIR} ]]; then
  echo "1 arg required, path to them directory."
  exit 1
fi

if [[ ! -d ${_THEME_DIR} ]]; then
  echo "'${_THEME_DIR}' not a dir"
  exit 1
fi

_GTK4_CONF="${HOME}/.config/gtk-4.0"
mkdir -p "${_GTK4_CONF}"
ln -sf "${_THEME_DIR}/gtk-4.0/assets" "${_GTK4_CONF}/assets"
ln -sf "${_THEME_DIR}/gtk-4.0/gtk.css" "${_GTK4_CONF}/gtk.css"
ln -sf "${_THEME_DIR}/gtk-4.0/gtk-dark.css" "${_GTK4_CONF}/gtk-dark.css"
