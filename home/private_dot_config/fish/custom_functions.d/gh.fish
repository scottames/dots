#!/bin/env fish

function gh \
    --description "wraps gh to ensure our token helper is always used" \
    --wraps gh

    if test -x $HOME/.local/bin/gh
        $HOME/.local/bin/gh $argv
    else
        command gh $argv
    end
end
