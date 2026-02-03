#!/bin/env fish

function secrettool_get_dots \
    --description "Get secret from keyring using dots schema (dots/<name>, \$GITHUB_USER)"

    # Usage: secrettool_get_dots <name> [--fallback <file>]
    # Schema: service="dots/<name>", username=$GITHUB_USER
    # Returns: secret value to stdout, exit 1 if not found

    argparse 'fallback=' -- $argv
    or return 1

    set -l name $argv[1]

    if test -z "$name"
        printf_err "Usage: secrettool_get_dots <name> [--fallback <file>]" >&2
        return 1
    end

    # Ensure GITHUB_USER is set
    if not set -q GITHUB_USER[1]; or test -z "$GITHUB_USER"
        printf_err "secrettool_get_dots: \$GITHUB_USER not set" >&2
        return 1
    end

    set -l service "dots/$name"
    set -l username "$GITHUB_USER"

    # Try keyring first
    set -l secret (secrettool_get "$service" "$username" 2>/dev/null)

    if test -n "$secret"
        echo $secret
        return 0
    end

    # Try fallback file if specified
    if test -n "$_flag_fallback"
        if test -f "$_flag_fallback"
            set -l file_secret (cat "$_flag_fallback" 2>/dev/null | string trim)
            if test -n "$file_secret"
                printf_debug "secrettool_get_dots: using fallback file $_flag_fallback"
                echo $file_secret
                return 0
            end
        end
    end

    return 1
end
