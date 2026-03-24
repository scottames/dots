#!/bin/env fish

function zellij_rename_tab
    set -l _argparse_options 'n/name=?'
    argparse -n ze $_argparse_options -- $argv

    set -l _TAB_NAME ""

    if set -q _flag_name
        set _TAB_NAME $_flag_name[1]
    else if set -q argv[1]
        set _TAB_NAME (zellij_tab_name $argv[1])
    else
        set _TAB_NAME (zellij_tab_name $PWD)
    end

    zellij action rename-tab $_TAB_NAME
end
