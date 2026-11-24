#!/bin/env fish

if status --is-interactive
    and type -q tv

    tv completions fish | source
end
