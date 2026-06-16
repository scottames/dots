#!/bin/env fish

if status --is-interactive
    and type -q mise

    mise activate fish | source
    # mise activation can rewrite PATH after __path.fish runs; keep local
    # wrappers like ~/.local/bin/gh ahead of mise shims.
    set -l _home_local_bin "$HOME_LOCAL_BIN"
    if test -z "$_home_local_bin"
        set _home_local_bin "$HOME/.local/bin"
    end
    fish_add_path --path -m "$_home_local_bin"
    mise completion fish | source
end
