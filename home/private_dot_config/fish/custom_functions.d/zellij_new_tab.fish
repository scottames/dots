#!/usr/bin/env fish

function zellij_new_tab \
    --description "Create a new Zellij tab with a named layout and derived name."

    argparse -n zellij_new_tab 'n/name=' 'l/layout=' -- $argv
    or return 1

    set -l target .
    if set -q argv[1]
        set target $argv[1]
    end

    if not test -e "$target"
        printf 'zellij_new_tab: path not found: %s\n' "$target" >&2
        return 1
    end

    set -l cwd "$target"
    if test -f "$cwd"
        set cwd (path dirname "$cwd")
    end
    set cwd (path resolve "$cwd")

    set -l layout split-edit
    if set -q _flag_layout
        set layout $_flag_layout
    end

    set -l tab_name
    if set -q _flag_name
        set tab_name $_flag_name
    else
        set tab_name (zellij_tab_name "$target")
    end

    command zellij action new-tab --layout "$layout" --cwd "$cwd" --name "$tab_name"
end
