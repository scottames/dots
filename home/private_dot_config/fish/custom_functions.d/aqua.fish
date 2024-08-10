#!/bin/env fish

function aqua \
    --description "Declarative CLI Version manager. Runs behind op, if installed for GitHub API auth." \
    --wraps aqua

    set -l _KEYRING_AUTH (GITHUB_TOKEN="" command gh auth status | grep 'keyring' | grep '✓ Logged in')
    if [ $_KEYRING_AUTH ]
        set -e GITHUB_TOKEN
        set -l GITHUB_TOKEN (gh auth token)

        command aqua $argv
    else if [ $HAS_OP ]
        op run -- gh $argv
    else
        command aqua $argv
    end
end
