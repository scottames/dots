#!/usr/bin/env fish

if not functions -q label_apply_substitutions
    source (path dirname (status filename))/label_apply_substitutions.fish
end

function project_label --description "Print a layout-aware project label for a path"
    argparse -n project_label 's/separator=' p/project-only -- $argv
    or return 1

    set -l separator :
    if set -q _flag_separator
        set separator $_flag_separator
    end

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
        label_apply_substitutions '~' "$PROJECT_LABEL_SUBSTITUTIONS"
        return 0
    end

    if not command git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1
        label_apply_substitutions (basename "$target") "$PROJECT_LABEL_SUBSTITUTIONS"
        return 0
    end

    set -l common_dir (command git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    set -l project_root
    set -l common_name (basename "$common_dir")

    set -l default_branch main
    set -l origin_head (command git -C "$target" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    if test -n "$origin_head"
        set default_branch (string replace 'refs/remotes/origin/' '' -- "$origin_head")
    end

    if test "$common_name" = .bare
        set project_root (path dirname "$common_dir")
    else if test "$common_name" = .git
        set -l primary_root (path dirname "$common_dir")
        set project_root "$primary_root"

        set -l primary_name (basename "$primary_root")
        if test "$primary_name" = "$default_branch"
            set -l candidate_root (path dirname "$primary_root")
            set -l candidate_project (basename "$candidate_root")
            set -l remote_project (command git -C "$target" config --get remote.origin.url 2>/dev/null \
                | string replace -r '^.*/' '' \
                | string replace -r '^.*:' '' \
                | string replace -r '\.git$' '')

            if test -n "$remote_project"; and test "$candidate_project" = "$remote_project"
                set project_root "$candidate_root"
            else
                set -l sibling_worktrees 0
                for worktree in (command git -C "$target" worktree list --porcelain 2>/dev/null \
                        | string match -r '^worktree ' \
                        | string replace 'worktree ' '')
                    if test (path dirname "$worktree") = "$candidate_root"
                        set sibling_worktrees (math $sibling_worktrees + 1)
                    end
                end

                if test $sibling_worktrees -gt 1
                    set project_root "$candidate_root"
                end
            end
        end
    else
        set project_root (string replace -r '/\.(git|bare)(/worktrees/[^/]+)?$' '' -- "$common_dir")
    end

    set -l project (basename "$project_root")
    if set -q _flag_project_only
        label_apply_substitutions "$project" "$PROJECT_LABEL_SUBSTITUTIONS"
        return 0
    end

    set -l label "$project"
    set -l branch (command git -C "$target" branch --show-current 2>/dev/null)
    if test -n "$branch"; and test "$branch" != "$default_branch"
        set label "$project$separator$branch"
    end

    label_apply_substitutions "$label" "$PROJECT_LABEL_SUBSTITUTIONS"
end
