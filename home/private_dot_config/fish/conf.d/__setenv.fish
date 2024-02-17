#!/bin/env fish

set -q XDG_CONFIG_HOME[1] \
    || set -x XDG_CONFIG_HOME "$HOME/.config"

set -x FISH_CONFIG "$XDG_CONFIG_HOME/fish"

set _setenv "$HOME/.setenv"
if test -f $_setenv
    source $_setenv
else
    printf_err "primary env file ($_setenv) not found and not sourced"
end
