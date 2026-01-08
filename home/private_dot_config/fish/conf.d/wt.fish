#!/bin/env fish

if status --is-interactive
    and type -q wt

    command wt config shell init fish | source
end
