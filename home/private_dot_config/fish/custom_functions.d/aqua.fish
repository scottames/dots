#!/bin/env fish

function aqua \
    --description "Declarative CLI Version Manager - with automatic GitHub token" \
    --wraps aqua

    # Resolve token fresh per-command for rate limits / private repos
    # Using -lx for local export: visible to child process, no stale global
    set -lx GITHUB_TOKEN (github_token_get)
    command aqua $argv
end
