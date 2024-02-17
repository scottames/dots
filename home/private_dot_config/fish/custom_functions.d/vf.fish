#!/bin/env fish

function vf --wraps fd
    fd --type f --hidden --exclude .git \
        | fzf-tmux -p --reverse \
        | xargs nvim
end
