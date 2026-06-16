#!/usr/bin/env fish

function label_apply_substitutions \
    --argument-names label substitutions \
    --description "Apply prefix substitutions to a label."

    if test -z "$substitutions"
        printf '%s\n' "$label"
        return 0
    end

    for substitution in (string split ' ' -- "$substitutions")
        set -l parts (string split --max 1 = -- "$substitution")
        if test (count $parts) -ne 2; or test -z "$parts[1]"
            continue
        end

        if string match -q "$parts[1]*" -- "$label"
            string replace -- "$parts[1]" "$parts[2]" "$label"
            return 0
        end
    end

    printf '%s\n' "$label"
end
