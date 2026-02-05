#!/bin/env fish

function github_token_load \
    --description "Load GITHUB_TOKEN into environment using layered resolution"

    # Already set - nothing to do
    if set -q GITHUB_TOKEN[1]; and test -n "$GITHUB_TOKEN"
        return 0
    end

    # Get token and source info in one call
    set -l json (github-token-get --json 2>/dev/null)
    if test -z "$json"
        printf_warn "No GitHub token available (ghtkn expired/missing, no PAT fallback)\n" >&2
        printf_info "  Run 'ghtkn get' to authenticate, or create ~/.gh.token\n" >&2
        return 1
    end

    set -l token (echo $json | jq -r '.token // empty')
    set -l source (echo $json | jq -r '.source')

    if test -z "$token" -o "$source" = none
        printf_warn "No GitHub token available (ghtkn expired/missing, no PAT fallback)\n" >&2
        printf_info "  Run 'ghtkn get' to authenticate, or create ~/.gh.token\n" >&2
        return 1
    end

    set -gx GITHUB_TOKEN $token
    printf_debug "github_token: using $source\n"
    return 0
end
