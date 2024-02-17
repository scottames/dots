#!/bin/env fish

function printf_color \
    --description "Wraps printf to print in the given color and style" \
    --wraps printf

    set _OPTS \
        bold \
        dim \
        italics \
        reverse \
        underline
    argparse --name printf_color \
        "c/color=" $_OPTS -- $argv
    or return

    for o in $_OPTS
        set _str (string split "/" -- "$o")[2]
        if set -ql _flag_$o
            set -a _FLAGS "--$o"
        end
    end

    set_color $_flag_color $_FLAGS
    printf $argv
    set_color normal
end
