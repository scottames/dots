#!/bin/env fish

if status --is-interactive
    and type -q mise

    mise activate fish | source
    fish_add_path --path -m "$HOME/.local/bin"
    mise completion fish | source
end
