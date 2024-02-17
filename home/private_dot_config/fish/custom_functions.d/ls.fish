#!/bin/env fish

function ls --wraps eza
    if [ $HAS_EZA ]
        eza --classify --group-directories-first $argv
    else
        command ls $argv
    end
end
