#!/usr/bin/env fish

function zellij_vertical_right --description "Start a new Zellij session with a right vertical status layout"
    set -l _config_dir "$HOME/.config/zellij/profiles/vertical-right"

    env ZELLIJ_STATUS_LAYOUT_MODE=vertical-right command zellij --config-dir "$_config_dir" -n default $argv
end
