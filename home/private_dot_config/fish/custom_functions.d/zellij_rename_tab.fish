#!/bin/env fish

function zellij_rename_tab
    set -l _argparse_options 'n/name=?'
    argparse -n ze $_argparse_options -- $argv

    set -l _TAB_NAME ""

    if set -q _flag_name
        set _TAB_NAME $_flag_name[1]
    else if set -q argv[1]
        set _TAB_NAME $argv[1]
    else if [ $PWD = $HOME ]
        set _TAB_NAME "~"
    else if [ $PWD = $DOTS ]
        set _TAB_NAME "."
    else
        set _TAB_NAME (ugum input --placeholder="New tab name?")
    end

    zellij action rename-tab $_TAB_NAME
end
