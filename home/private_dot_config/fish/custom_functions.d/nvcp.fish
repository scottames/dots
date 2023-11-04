#!/bin/env fish

function nvcp \
    --description "interactive ls + copy to clipboard"

    if not type -q nav
        print_err "missing 'nav' in path"
        return 1
    end

    nav --pipe $argv | setclip
end
