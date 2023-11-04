#!/bin/env fish

function nv \
    --description "interactive ls + cd"

    if not type -q nav
        print_err "missing 'nav' in path"
        return 1
    end

    cd (nav --pipe $argv)
end
