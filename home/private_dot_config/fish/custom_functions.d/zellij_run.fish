#!/bin/env fish

function zellij_run
    set -l _argparse_options f/floating
    argparse -n ze $_argparse_options -- $argv

    set -l _FLOATING ""
    if set -q _flag_floating
        set _FLOATING " --floating"
    end

    command zellij run --name "$argv"$_FLOATING -- fish -c "$argv"
end
