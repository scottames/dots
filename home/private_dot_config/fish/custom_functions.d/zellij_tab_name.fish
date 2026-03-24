#!/usr/bin/env fish

function zellij_tab_name --description "Print a stable Zellij tab name for a path"
    set -l target .
    if set -q argv[1]
        set target $argv[1]
    end

    if test -f "$target"
        set target (path dirname "$target")
    else if not test -d "$target"
        set -l parent (path dirname "$target")
        if test -d "$parent"
            set target "$parent"
        end
    end

    if test -d "$target"
        set target (path resolve "$target")
    end

    if test "$target" = (path resolve "$HOME")
        printf '~\n'
        return 0
    end

    if command git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l common_dir (command git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
        set -l project_root (string replace -r '/\.(git|bare)(/worktrees/[^/]+)?$' '' -- "$common_dir")
        set -l project (basename "$project_root")
        set -l branch (command git -C "$target" branch --show-current 2>/dev/null)
        set -l default_branch main
        set -l origin_head (command git -C "$target" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
        if test -n "$origin_head"
            set default_branch (string replace 'refs/remotes/origin/' '' -- "$origin_head")
        end

        if test -n "$branch"; and test "$branch" != "$default_branch"
            printf '%s.%s\n' "$project" "$branch"
        else
            printf '%s\n' "$project"
        end
        return 0
    end

    printf '%s\n' (basename "$target")
end
