#!/bin/env fish

function fzfpr --wraps "gh pr list" --description "Fzf query PRs via gh"
    set -l options c/checkout
    argparse -n fzfpr $options -- $argv
    or return

    # Set token for this function scope - exported to fzf and its preview subshells
    set -lx GITHUB_TOKEN (github_token_get)

    set _pr (GH_FORCE_TTY=100% \
    command gh pr list $argv \
    | fzf --ansi --preview "GH_FORCE_TTY=100% gh pr view {1}" \
          --preview-window down --header-lines 3 \
    | awk '{print $1}')

    if set -q _flag_checkout
        command gh pr checkout (string replace "#" "" $_pr)
    else
        echo $_pr
    end
end
