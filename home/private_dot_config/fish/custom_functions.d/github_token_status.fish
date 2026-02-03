#!/bin/env fish

function github_token_status \
    --description "Show current GitHub token resolution status"

    # Force autoload of github_token_get.fish to ensure helpers are available
    true; and functions -q github_token_get; and builtin source (functions --details github_token_get)

    echo "GitHub Token Status:"
    echo "---"

    # Current GITHUB_TOKEN
    if set -q GITHUB_TOKEN[1]; and test -n "$GITHUB_TOKEN"
        printf_green_bold "  GITHUB_TOKEN: set ($(string sub -l 10 $GITHUB_TOKEN)...)"
    else
        printf_yellow "  GITHUB_TOKEN: not set"
    end

    # CI mode
    if set -q CI[1]; and test "$CI" = "true"
        printf_info "  CI mode: yes (token disabled)"
    else
        echo "  CI mode: no"
    end

    # ghtkn status
    if not command -q secret-tool
        printf_warn "  ghtkn: secret-tool not installed (keyring unavailable)"
    else if not command -q jq
        printf_warn "  ghtkn: jq not installed (can't parse token)"
    else if not command -q yq
        printf_warn "  ghtkn: yq not installed (can't read config)"
    else if not test -f "$_GHTKN_CONFIG_FILE"
        printf_warn "  ghtkn: config not found ($_GHTKN_CONFIG_FILE)"
    else if _ghtkn_has_valid_token
        set -l client_id (_ghtkn_client_id)
        set -l secret (secret-tool lookup \
            service "$_GHTKN_KEYRING_SERVICE" \
            username "$client_id" 2>/dev/null)
        set -l exp (echo $secret | jq -r '.expiration_date' 2>/dev/null)
        printf_green_bold "  ghtkn: valid (expires $exp)"
    else
        printf_yellow "  ghtkn: expired or missing - run 'ghtkn get' to refresh"
    end

    # PAT fallback
    if test -f "$_GITHUB_TOKEN_PAT_FILE"
        printf_green "  PAT fallback: available ($_GITHUB_TOKEN_PAT_FILE)"
    else
        printf_yellow "  PAT fallback: not found ($_GITHUB_TOKEN_PAT_FILE)"
    end
end
