#!/bin/env fish

function aqua \
    --description "Declarative CLI Version manager. Runs behind op, if installed for GitHub API auth." \
    --wraps aqua

    set -l _GH_AUTH_STATUS (GITHUB_TOKEN="" command gh auth status)
    if string match -q -r "✓ Logged in" $_GH_AUTH_STATUS
        set -l GITHUB_TOKEN (gh auth token)

        command aqua $argv
    else if [ $HAS_OP ]
        op run -- aqua $argv
    else
        command aqua $argv
    end
end
