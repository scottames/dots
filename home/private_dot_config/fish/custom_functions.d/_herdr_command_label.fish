#!/usr/bin/env fish

if not functions -q label_apply_substitutions
    source (path dirname (status filename))/label_apply_substitutions.fish
end

function _herdr_command_label \
    --description "Print a compact label for a command line."

    set -l command_line (string trim -- (string join ' ' -- $argv))
    if test -z "$command_line"
        printf 'fish\n'
        return 0
    end

    set -l words (string split -n -- ' ' "$command_line")
    set -l label
    set -l skip_nono_wrap false

    for word in $words
        if test "$skip_nono_wrap" = true
            if test "$word" = --
                set skip_nono_wrap false
            end
            continue
        end

        switch $word
            case command builtin exec env sudo
                continue
            case nono nono-with-local-path
                set skip_nono_wrap true
                continue
            case nntd
                continue
            case '*=*'
                continue
            case '-*'
                continue
        end

        set label (path basename -- "$word")
        break
    end

    if test -z "$label"
        set label (path basename -- "$words[1]")
    end

    label_apply_substitutions (string sub --length 40 -- "$label") "$COMMAND_LABEL_SUBSTITUTIONS"
end
