#!/bin/env fish

function secrettool_get \
    --description "Get secret from system keyring (GNOME Keyring / libsecret)"

    # Usage: secrettool_get <service> <username>
    # Returns: secret value to stdout, exit 1 if not found

    set -l service $argv[1]
    set -l username $argv[2]

    if test -z "$service" -o -z "$username"
        printf_err "Usage: secrettool_get <service> <username>" >&2
        return 1
    end

    if not command -q secret-tool
        printf_err "secrettool_get: secret-tool not installed (libsecret)" >&2
        return 1
    end

    set -l secret (secret-tool lookup service "$service" username "$username" 2>/dev/null)

    if test -z "$secret"
        return 1
    end

    echo $secret
end
