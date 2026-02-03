#!/bin/env fish

function github_token_status \
    --description "Show current GitHub token resolution status"

    # Force autoload of github_token_get.fish to ensure helpers are available
    true; and functions -q github_token_get; and builtin source (functions --details github_token_get)

    echo # give it some space

    printf_white "  GITHUB_TOKEN: "
    if set -q GITHUB_TOKEN[1]; and test -n "$GITHUB_TOKEN"
        printf_yellow "set ($(string sub -l 10 $GITHUB_TOKEN)...)\n"
    else
        printf_blue "not set\n"
    end

    # CI mode
    printf_white "  CI mode: "
    if set -q CI[1]; and test "$CI" = true
        printf_yellow "     yes (token disabled)\n"
    else
        printf_blue "     no\n"
    end

    # ghtkn env overrides
    if set -q GHTKN_APP[1]; and test -n "$GHTKN_APP"
        printf_white "  GHTKN_APP: "
        printf_blue "   $GHTKN_APP\n"
    end
    if set -q GHTKN_CONFIG[1]; and test -n "$GHTKN_CONFIG"
        printf_white "  GHTKN_CONFIG: "
        printf_blue "$GHTKN_CONFIG\n"
    end

    # ghtkn status
    set -l cfg (_ghtkn_config_file)
    if not command -q secret-tool
        printf_warn "  secret-tool not installed (keyring unavailable)\n"
    else if not command -q jq
        printf_warn "  jq not installed (can't parse token)\n"
    else if not command -q yq
        printf_warn "  yq not installed (can't read config)\n"
    else if not test -f "$cfg"
        printf_warn "  config not found ($cfg)\n"
    else if _ghtkn_has_valid_token
        set -l app (_ghtkn_app_name)
        set -l client_id (_ghtkn_client_id)
        set -l secret (secret-tool lookup \
            service "$_GHTKN_KEYRING_SERVICE" \
            username "$client_id" 2>/dev/null)
        set -l exp (echo $secret | jq -r '.expiration_date' 2>/dev/null)
        set -l exp_friendly (date -d "$exp" "+%Y-%m-%d %l:%M %p %Z" 2>/dev/null | string trim)
        printf_white "  ghtkn: \n"
        printf_green "    valid:   $app\n"
        printf_green "    expires: $exp_friendly\n"
    else
        set -l app (_ghtkn_app_name)
        printf "  ghtkn: "
        printf_yellow "  expired or missing [$app] - run 'ghtkn get' to refresh\n"
    end

    printf_white "  PAT fallback: \n"
    printf_white "    keyring: "
    if command -q secret-tool
        set -l pat_secret (secrettool_get "dots/github-pat" "$GITHUB_USER" 2>/dev/null)
        if test -n "$pat_secret"
            printf_green "available\n"
        else
            printf_blue "not found\n"
        end
    else
        printf_yellow "secret-tool not installed\n"
    end
    printf_white "    file:    "
    if test -f "$_GITHUB_TOKEN_PAT_FILE"
        printf_green "available "
    else
        printf_blue "not found "
    end
    printf_white "("
    printf_blue "$_GITHUB_TOKEN_PAT_FILE"
    printf_white ")\n"
end
