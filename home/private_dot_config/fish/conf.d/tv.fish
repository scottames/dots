#!/bin/env fish

if status --is-interactive
    and type -q tv

    tv init fish | source
end
