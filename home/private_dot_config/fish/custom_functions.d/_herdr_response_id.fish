#!/usr/bin/env fish

function _herdr_response_id \
    --description "Extract the first matching ID field from Herdr JSON."

    argparse -n _herdr_response_id -- $argv
    or return 1

    if not set -q argv[1]
        printf '_herdr_response_id: field name required\n' >&2
        return 1
    end

    if not set -q argv[2]
        printf '_herdr_response_id: JSON payload required\n' >&2
        return 1
    end

    if not type -q jq
        printf '_herdr_response_id: jq is required\n' >&2
        return 1
    end

    set -l field $argv[1]
    set -l json $argv[2]
    set -l ids (printf '%s\n' "$json" | command jq -r --arg field "$field" '.. | objects | .[$field]? // empty')
    or return 1

    if test -z "$ids[1]"
        printf '_herdr_response_id: field not found: %s\n' "$field" >&2
        return 1
    end

    printf '%s\n' "$ids[1]"
end
