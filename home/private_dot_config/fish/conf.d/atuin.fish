#!/bin/env fish

if status --is-interactive
    and type -q atuin

    atuin init fish | source
end
