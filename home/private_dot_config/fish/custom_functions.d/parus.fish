#!/bin/env fish

function parus --description "fzf install paru packages"
    paru -Sl | awk '{print $2($4=="" ? "" : " *")}' | fzf --multi --preview 'paru -Si {1}' --reverse | xargs -ro paru -S
end
