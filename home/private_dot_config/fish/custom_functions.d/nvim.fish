#!/bin/env fish

function nvim
    if $HAS_DISTROBOXHOSTEXEC
        and ! is_distrobox >/dev/null
        and set -q DISTROBOX_DEFAULT

        distrobox enter \
            $DISTROBOX_DEFAULT -- nvim $argv
    else
        command nvim $argv
    end
end
