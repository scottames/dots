#!/bin/env fish

function git_clone_for_worktrees_from_ls \
    --description "Calls git_clone_for_worktrees on all directories in pwd. Needs "
    # Examples:
    #   git_clone_for_worktrees_from_ls scottames
    #     => sets up subdirectories repos for org 'scottames'

    argparse b/bare -- $argv || return 1

    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        printf_err "Usage: git_clone_for_worktrees_from_ls [--bare] <org> [remote]\n"
        return 1
    end

    set -l org $argv[1]
    set -l remote "github.com"
    if test (count $argv) -eq 2
        set remote $argv[2]
    end

    set -l mode_args
    if set -q _flag_bare
        set mode_args --bare
    end

    echo "remote: $remote"
    for dir in */
        set dir (string trim --right --chars=/ "$dir")
        git_clone_for_worktrees $mode_args "git@$remote/$org/$dir.git"
    end
end
