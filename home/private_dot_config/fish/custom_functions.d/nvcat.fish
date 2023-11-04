#!/bin/env fish

function nvcat \
    --description "interactive ls + multi cat"

    if not type -q nav
        print_err "missing 'nav' in path"
        return 1
    end

    nav --pipe $argv | xargs cat
end
