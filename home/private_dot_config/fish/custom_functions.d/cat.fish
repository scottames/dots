#!/bin/env fish

function cat --wraps bat --description "alias cat to bat"
    if $HAS_BAT
        bat $argv
    else
        command cat $argv
    end
end
