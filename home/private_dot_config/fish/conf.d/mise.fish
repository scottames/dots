#!/bin/env fish

if status --is-interactive
    and type -q mise

    mise activate fish | source

    if ! test -f $FISH_CONFIG/completions/mise.fish
        mise completion fish >$FISH_CONFIG/completions/mise.fish
    end
end
