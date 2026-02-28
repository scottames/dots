#!/bin/env fish

# gt-wt-create: Create a new Graphite-tracked branch and switch to its worktree
#
#   source: https://zander.wtf/notes/graphite-worktrees
#
# Requirements:
# - Graphite CLI (gt): https://graphite.dev/
# - Worktrunk CLI (wt): https://worktrunk.dev/
#
# Usage: gt-wt-create [-b/--base BASE] [--no-cd] <branchName>
#
# Options:
#   -b/--base BASE  Base branch for the new branch (default: default branch)
#   --no-cd         Create the worktree but don't cd into it
#
# Development Workflow:
# 1. Run this function to create and switch to a new worktree branch
# 2. Use `gt modify` to make your initial changes (not `gt create`, branch is already checked out)
# 3. Use normal gt operations for submitting and stacking (`gt submit`, `gt create` for stacks, etc.)
#
# When done with a stack:
# 1. Run `gt sync`
# 2. Do NOT accept deleting your worktree branches when prompted
# 3. Checkout your worktree branch and rebase it to main
# 4. Proceed with new work from there

function gt-wt-create
    argparse 'b/base=' 'no-cd' -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "Usage: gt-wt-create [-b/--base BASE] [--no-cd] <branchName>"
        return 1
    end

    set -l branch_name $argv[1]
    set -l base_args
    if set -q _flag_base
        set base_args $_flag_base
    end

    git branch $branch_name $base_args
    or return 1

    git switch $branch_name
    or return 1

    gt track
    or return 1

    git switch -
    or return 1

    if set -q _flag_no_cd
        wt switch --no-cd $branch_name
    else
        wt switch $branch_name
    end
end
