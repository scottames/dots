#!/bin/env fish

function github_token_load \
    --description "Load GITHUB_TOKEN into environment using layered resolution"

    # Ensure helpers from github_token_get.fish are loaded
    functions -q github_token_get; and builtin source (functions --details github_token_get) 2>/dev/null

    # Already set - nothing to do
    if set -q GITHUB_TOKEN[1]; and test -n "$GITHUB_TOKEN"
        return 0
    end

    # CI mode - intentionally no token
    if set -q CI[1]; and test "$CI" = true
        printf_debug "github_token: CI mode, skipping token"
        return 1
    end

    # Try ghtkn first
    if _ghtkn_has_valid_token
        set -l token (_github_token_from_ghtkn)
        if test -n "$token"
            set -gx GITHUB_TOKEN $token
            printf_debug "github_token: using ghtkn [(_ghtkn_app_name)]"
            return 0
        end
    end

    # Fallback to PAT
    if test -f "$_GITHUB_TOKEN_PAT_FILE"
        set -l token (cat "$_GITHUB_TOKEN_PAT_FILE")
        if test -n "$token"
            set -gx GITHUB_TOKEN $token
            printf_debug "github_token: using PAT fallback"
            return 0
        end
    end

    # No token available - warn user
    printf_warn "No GitHub token available (ghtkn expired/missing, no PAT fallback)" >&2
    printf_info "  Run 'ghtkn get' to authenticate, or create ~/.gh.token" >&2
    return 1
end
