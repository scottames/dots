#!/bin/env fish

if status --is-interactive
    and type -q mise

    mise activate fish | source

    function __dots_local_bin_first --description "Keep ~/.local/bin ahead of mise's tool paths"
        set -l home_local_bin "$HOME_LOCAL_BIN"
        test -z "$home_local_bin"; and set home_local_bin "$HOME/.local/bin"
        fish_add_path --global --move --path "$home_local_bin"
    end

    function __dots_local_bin_first_on_pwd --on-variable PWD
        __dots_local_bin_first
    end

    function __dots_local_bin_first_on_prompt --on-event fish_prompt
        __dots_local_bin_first
    end

    __dots_local_bin_first
    mise completion fish | source
end
