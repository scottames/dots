#!/usr/bin/env fish

function _herdr_command_label \
    --description "Print a compact label for a command line."

    set -l command_line (string trim -- (string join ' ' -- $argv))
    if test -z "$command_line"
        printf 'fish\n'
        return 0
    end

    set -l words (string split -n -- ' ' "$command_line")
    set -l label

    for word in $words
        switch $word
            case command builtin exec env sudo
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

    printf '%s\n' (string sub --length 40 -- "$label")
end
