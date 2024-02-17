#!/bin/env fish

function fzpr --wraps "gh pr list" --description "Fzf query PRs via gh"
    set -l options c/checkout
    argparse -n fzpr $options -- $argv
    or return

    set _pr (GH_FORCE_TTY=100% \
    op run -- gh pr list $argv \
    | fzf --ansi --preview "GH_FORCE_TTY=100% op run -- gh pr view {1}" \
          --preview-window down --header-lines 3 \
    | awk '{print $1}')

    if set -q _flag_checkout
        gh pr checkout (string replace "#" "" $_pr)
    else
        echo $_pr
    end
end
