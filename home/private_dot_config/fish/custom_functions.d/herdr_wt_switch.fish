#!/usr/bin/env fish

function herdr_wt_switch --description "Open a Stax worktree in Herdr"
    argparse --max-args=1 c/create b/base= h/help -- $argv
    or return 2
    if set -q _flag_help
        printf 'Usage: herdr_wt_switch [--create] [--base BASE] [BRANCH]\n'
        printf 'Creation defaults to trunk; --base @ explicitly uses the current branch.\n'
        return 0
    end
    if set -q HC_TERMINAL_ID
        command herdr-app ls >/dev/null
        or return 1
    end
    set -l primary (_stax_primary_worktree)
    or return 1
    set -l options
    set -q _flag_create; and set -a options --create
    set -q _flag_base; and set -a options --base "$_flag_base"
    set -l destination (_stax_worktree_path $options $argv)
    or return $status
    test -n "$destination"; or return 0
    herdr_open_worktree_path "$primary" "$destination"
end
