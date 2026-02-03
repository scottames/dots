#!/bin/env fish

function aqua \
    --description "Declarative CLI Version Manager - with automatic GitHub token" \
    --wraps aqua

    # Load token for rate limits / private repos
    github_token_load
    command aqua $argv
end
