#!/bin/env fish

function gh \
    --description "GitHub CLI. Runs behind op, if installed for GitHub API auth." \
    --wraps gh

    set -l _GH_AUTH_STATUS (GITHUB_TOKEN="" command gh auth status)
    if string match -q -r "✓ Logged in" $_GH_AUTH_STATUS
        GITHUB_TOKEN="" command gh $argv
    else if [ $HAS_OP ]
        op run -- gh $argv
    else
        command gh $argv
    end
end
