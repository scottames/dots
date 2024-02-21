#!/usr/bin/env fish

function zellij_new_tab \
    --description "Wraps zellij new-tab with some opinions."

    set -l _argparse_options 'c/cwd=?' 's/split=?' 'n/name=?' 'l/layout=?'
    argparse -n ze $_argparse_options -- $argv

    set -l _DIR ""
    set -l _CWD ""
    set -l _SPLIT ""
    set -l _LAYOUT ""
    set -l _NAME ""

    if set -q _flag_cwd
        set _CWD "--cwd $_flag_cwd"
        set _DIR $_flag_cwd
    end

    if set -q _flag_split
        set _SPLIT "--$_flag_split"
    end

    if set -q _flag_layout
        set _LAYOUT "--layout $_flag_layout"
    end

    if set -q _flag_name
        set _NAME "--name $_flag_name"
    end

    zellij_new_tab_edit_split $_SPLIT $LAYOUT $NAME $DIR
end
