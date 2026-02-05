#!/bin/env fish

function github_token_status \
    --description "Show current GitHub token resolution status"

    # Get all status info in one call
    set -l json (github-token-get --json 2>/dev/null)
    if test -z "$json"
        printf_err "  Failed to get token status\n"
        return 1
    end

    # Parse JSON fields
    set -l token (echo $json | jq -r '.token // empty')
    set -l source (echo $json | jq -r '.source')
    set -l ci_mode (echo $json | jq -r '.ci_mode')
    set -l ghtkn_app (echo $json | jq -r '.ghtkn.app')
    set -l ghtkn_config (echo $json | jq -r '.ghtkn.config')
    set -l ghtkn_config_exists (echo $json | jq -r '.ghtkn.config_exists')
    set -l ghtkn_valid (echo $json | jq -r '.ghtkn.valid')
    set -l ghtkn_expires_friendly (echo $json | jq -r '.ghtkn.expires_friendly // empty')
    set -l pat_keyring (echo $json | jq -r '.pat.keyring_available')
    set -l pat_file_exists (echo $json | jq -r '.pat.file_exists')
    set -l pat_file_path (echo $json | jq -r '.pat.file_path')

    echo # spacing

    # GITHUB_TOKEN env var
    printf_white "  GITHUB_TOKEN: "
    if set -q GITHUB_TOKEN[1]; and test -n "$GITHUB_TOKEN"
        printf_yellow "set ($(string sub -l 10 $GITHUB_TOKEN)...)\n"
    else
        printf_blue "not set\n"
    end

    # CI mode
    printf_white "  CI mode:      "
    if test "$ci_mode" = true
        printf_yellow "yes (token disabled)\n"
    else
        printf_blue "no\n"
    end

    # ghtkn env overrides (only show if set)
    if set -q GHTKN_APP[1]; and test -n "$GHTKN_APP"
        printf_white "  GHTKN_APP:    "
        printf_blue "$GHTKN_APP\n"
    end
    if set -q GHTKN_CONFIG[1]; and test -n "$GHTKN_CONFIG"
        printf_white "  GHTKN_CONFIG: "
        printf_blue "$GHTKN_CONFIG\n"
    end

    # ghtkn status
    if test "$ghtkn_config_exists" = false
        printf_warn "  ghtkn: config not found ($ghtkn_config)\n"
    else if test "$ghtkn_valid" = true
        printf_white "  ghtkn:\n"
        printf_green "    valid:   $ghtkn_app\n"
        printf_green "    expires: $ghtkn_expires_friendly\n"
    else
        printf_white "  ghtkn: "
        printf_yellow "expired or missing [$ghtkn_app] - run 'ghtkn get' to refresh\n"
    end

    # PAT fallback
    printf_white "  PAT fallback:\n"
    printf_white "    keyring: "
    if test "$pat_keyring" = true
        printf_green "available\n"
    else
        printf_blue "not found\n"
    end
    printf_white "    file:    "
    if test "$pat_file_exists" = true
        printf_green "available "
    else
        printf_blue "not found "
    end
    printf_white "("
    printf_blue "$pat_file_path"
    printf_white ")\n"

    # Active source summary
    printf_white "  Source:    "
    switch $source
        case env
            printf_yellow "env (GITHUB_TOKEN already set)\n"
        case ghtkn
            printf_green "ghtkn\n"
        case pat_keyring
            printf_blue "PAT keyring\n"
        case pat_file
            printf_blue "PAT file\n"
        case none
            printf_yellow "none\n"
    end
end
