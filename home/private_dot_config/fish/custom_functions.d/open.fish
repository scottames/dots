#!/bin/env fish

function open --wraps xdg-open
    if type -q xdg-open
        xdg-open $argv
    else
        printf_err "no suitable opener found\n"
        return 1
    end
end
