#!/bin/env fish

if status --is-interactive
    and type -q stax

    stax setup --print | source
    # Upstream's `type -p stax` resolves the sourced function to "-", not the CLI.
    set -g __STAX_BIN (command -s stax)
end
