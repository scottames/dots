#!/bin/env fish

function distrobox_enter \
    --description "wraps 'distrobox enter' for fuzzy choosing container"

    set -l gumBin

    if test -z $GUM_BINZ
        printf_err "missing gum/ugum!"
        return 1
    end

    set -l box (distrobox ls | tail -n +2 | tr -s ' ' | cut -d ' ' -f 3,8-9 | $GUM_BIN choose | cut -d ' ' -f 1)
    distrobox enter $box
end
