#!/bin/env fish

function zellij \
    --description "Wraps zellij enabling catppuccin-latte theme during daylight hours"

    if is_light >/dev/null
        if test (count $argv) -lt 1
            or test $argv[1] = attach -o $argv[1] = a

            command zellij $argv options --theme catppuccin-latte
        end
    end

    command zellij $argv
end
