#!/bin/env fish

function ls --wraps eza
    if command -q eza
        eza --classify --group-directories-first $argv
    else
        command ls $argv
    end
end
