#!/bin/env fish

function secrettool_set \
    --description "Store secret in system keyring (GNOME Keyring / libsecret)"

    # Usage: secrettool_set <service> <username> [--label <label>]
    # Reads secret value from stdin
    # Example: echo "my-secret" | secrettool_set "my-service" "my-user" --label "My Secret"

    argparse 'label=' -- $argv
    or return 1

    set -l service $argv[1]
    set -l username $argv[2]

    if test -z "$service" -o -z "$username"
        printf_err "Usage: secrettool_set <service> <username> [--label <label>]" >&2
        printf_info "  Reads secret value from stdin" >&2
        return 1
    end

    if not command -q secret-tool
        printf_err "secrettool_set: secret-tool not installed (libsecret)" >&2
        return 1
    end

    set -l label $_flag_label
    if test -z "$label"
        set label "$service/$username"
    end

    # Read from stdin and store
    secret-tool store --label="$label" service "$service" username "$username"
end
