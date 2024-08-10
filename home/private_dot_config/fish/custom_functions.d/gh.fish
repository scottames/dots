#!/bin/env fish

function gh \
    --description "GitHub CLI. Runs behind op, if installed for GitHub API auth." \
    --wraps gh

    set -l _KEYRING_AUTH (GITHUB_TOKEN="" command gh auth status | grep 'keyring' | grep '✓ Logged in')
    if [ $_KEYRING_AUTH ]
        set -e GITHUB_TOKEN

        command gh $argv
    else if [ $HAS_OP ]
        op run -- gh $argv
    else
        command gh $argv
    end
end
