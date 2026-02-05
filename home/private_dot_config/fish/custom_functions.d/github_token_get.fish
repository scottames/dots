#!/bin/env fish

# GitHub token resolution - thin wrapper around github-token-get script
#
# Usage:
#   github_token_get         # Output token (or return 1 if none)
#   github_token_get --json  # Output status info + token as JSON
#
# The script handles the full resolution chain:
#   1. $GITHUB_TOKEN already set → use it
#   2. CI environment → no token
#   3. ghtkn has valid cached token → use it
#   4. PAT fallback (keyring → file)
#
# Environment variables respected by the script:
#   GHTKN_APP    - Override ghtkn app name (default: $GITHUB_USER/ghtkn)
#   GHTKN_CONFIG - Override ghtkn config path (default: ~/.config/ghtkn/ghtkn.yaml)

function github_token_get \
    --description "Get GitHub token using layered resolution (ghtkn → PAT fallback)"

    github-token-get $argv
end
