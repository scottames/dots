#!/bin/env fish

function zellij_edit
    set -l _argparse_options t/tab f/floating
    argparse -n ze $_argparse_options -- $argv

    if set -q _flag_floating
        if set -q _flag_tab
            print_warn "cannot float a tab!\n"
        else
            set -p argv --floating
        end
    end

    if set -q _flag_tab
        zellij_new_tab_edit_split $argv
    else
        command zellij edit $argv
    end
end
