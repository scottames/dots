#!/bin/env fish

function gh \
    --description "GitHub CLI with automatic token resolution" \
    --wraps gh

    # If gh is already authenticated via `gh auth login`, use that
    # (avoids GITHUB_TOKEN conflicts, allows broader scopes)
    set -l _auth_status (GITHUB_TOKEN="" command gh auth status 2>&1)
    if string match -q -r "✓ Logged in" "$_auth_status"
        GITHUB_TOKEN="" command gh $argv
        return $status
    end

    # Otherwise, resolve token fresh per-command (ghtkn → PAT fallback)
    # Using -lx for local export: visible to child process, no stale global
    set -lx GITHUB_TOKEN (github_token_get)
    command gh $argv
end
