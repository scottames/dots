#!/bin/env fish

function aqua \
    --description "Declarative CLI Version manager. Runs behind op, if installed for GitHub API auth." \
    --wraps aqua

    if [ $HAS_GHTKN ]
        github_token_load
        command aqua $argv
    else
        command aqua $argv
    end
end
