#!/bin/env fish

function git_checkout_fzf --description "Git checkout branch via fzf"
    git branch --sort=-committerdate \
        | fzf --header 'checkout recent branch' \
        --preview 'git -c color.ui=always diff {1}' \
        --pointer '' \
        | xargs git checkout
end
