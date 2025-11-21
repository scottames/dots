#!/bin/env fish

if status --is-interactive
    and type -q just

    just --completions fish | source
end
