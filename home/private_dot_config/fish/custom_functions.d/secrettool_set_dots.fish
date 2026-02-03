#!/bin/env fish

function secrettool_set_dots \
    --description "Store secret in keyring using dots schema (dots/<name>, \$GITHUB_USER)"

    # Usage: secrettool_set_dots <name> [--label <label>]
    # Schema: service="dots/<name>", username=$GITHUB_USER
    # Reads secret value from stdin
    # Example: echo "my-api-key" | secrettool_set_dots tavily --label "Tavily API Key"

    argparse 'label=' -- $argv
    or return 1

    set -l name $argv[1]

    if test -z "$name"
        printf_err "Usage: secrettool_set_dots <name> [--label <label>]" >&2
        printf_info "  Reads secret value from stdin" >&2
        printf_info "  Example: echo 'my-secret' | secrettool_set_dots my-name --label 'My Secret'" >&2
        return 1
    end

    # Ensure GITHUB_USER is set
    if not set -q GITHUB_USER[1]; or test -z "$GITHUB_USER"
        printf_err "secrettool_set_dots: \$GITHUB_USER not set" >&2
        return 1
    end

    set -l service "dots/$name"
    set -l username "$GITHUB_USER"

    set -l label $_flag_label
    if test -z "$label"
        set label "dots: $name"
    end

    # Pass through to generic secrettool_set
    secrettool_set "$service" "$username" --label "$label"
end
