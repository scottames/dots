#!/bin/env fish

function git_clone_for_worktrees_from_ls \
    --description "Calls git_clone_for_worktrees on all directories in pwd. Needs "
    # Examples:
    #   git_clone_for_worktrees_from_ls scottames
    #     => sets up subdirectories repos for org 'scottames'

    _arg_req_gt_one $argv || return 1

    set -l org $argv[1]
    set -l remote $argv[2]

    if set -q argv[2]
        set remote $argv[2]
    else
        set remote "github.com"
    end

    echo "remote: $remote"
    for dir in (ls -D)
        git_clone_for_worktrees "git@$remote/$org/$dir.git"
    end
end
