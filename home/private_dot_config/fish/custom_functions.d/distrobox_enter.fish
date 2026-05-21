#!/bin/env fish

function distrobox_enter \
    --description "wraps 'distrobox enter' for fuzzy choosing container"

    if not type -q gum
        printf_err "missing gum!"
        return 1
    end

    set -l box (distrobox ls | tail -n +2 | tr -s ' ' | cut -d ' ' -f 3,8-9 | gum choose | cut -d ' ' -f 1)
    distrobox enter $box
end
