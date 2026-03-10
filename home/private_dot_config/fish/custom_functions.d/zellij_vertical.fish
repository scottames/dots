#!/usr/bin/env fish

function zellij_vertical --description "Start a new Zellij session with a left vertical status layout"
    set -l _config_dir "$HOME/.config/zellij/profiles/vertical"

    env ZELLIJ_STATUS_LAYOUT_MODE=vertical command zellij --config-dir "$_config_dir" -n default $argv
end
