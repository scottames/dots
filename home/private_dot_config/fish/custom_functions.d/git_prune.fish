#!/bin/env fish

function git_prune --description "Preview integrated worktree and branch cleanup; --apply to remove"
    argparse --max-args=0 apply 'min-age=' h/help -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: git_prune [--apply] [--min-age=2d]' \
            '' \
            'Preview only by default: no fetch, deletion, or metadata repair.' \
            '--apply requires the clean primary worktree on its default branch.' \
            'It pulls with --ff-only, then removes integrated worktrees and branches.' \
            'Dirty, locked, and recent worktrees are skipped by Worktrunk.' \
            'Save ignored artifacts and stop active agents before applying.' \
            'Stax metadata repairs and closed/unmerged PRs need separate review.'
        return 0
    end

    if not command -q wt
        printf 'git_prune: Worktrunk (wt) is required.\n' >&2
        return 1
    end
    command git rev-parse --show-toplevel >/dev/null 2>&1
    or return 1

    set -l min_age 2d
    if set -q _flag_min_age
        set min_age "$_flag_min_age"
    end
    set -l stax_repo false
    if command git show-ref --verify --quiet refs/stax/trunk
        set stax_repo true
        if not command -q stax
            printf 'git_prune: this repository requires Stax for metadata checks.\n' >&2
            return 1
        end
        if set -q _flag_apply; and not command -q jq
            printf 'git_prune: jq is required to check deleted Stax branches.\n' >&2
            return 1
        end
    end

    if set -q _flag_apply
        set -l primary (command wt step eval '{{ primary_worktree_path }}')
        or return $status
        set -l default_branch (command wt step eval '{{ default_branch }}')
        or return $status
        set -l root (command git rev-parse --show-toplevel)
        set -l branch (command git branch --show-current)
        if test "$root" != "$primary"; or test "$branch" != "$default_branch"
            printf 'git_prune: run --apply from %s on branch %s.\n' "$primary" "$default_branch" >&2
            return 1
        end
        set -l changes (command git status --porcelain)
        or return $status
        if test (count $changes) -gt 0
            printf 'git_prune: the primary worktree must be clean; nothing was pruned.\n' >&2
            return 1
        end
        command git pull --ff-only
        or return $status
    end

    printf 'Cleanup preview (minimum age: %s):\n' "$min_age"
    command wt step prune --dry-run --min-age="$min_age"
    or return $status

    if not set -q _flag_apply
        if test "$stax_repo" = true
            command stax fix --dry-run
            or return $status
        end
        printf '\nPreview only. Review ignored artifacts and active agents, then use git_prune --apply.\n'
        return 0
    end

    if test "$stax_repo" = true
        set -l removals (command wt step prune --min-age="$min_age" --foreground --format=json)
        or return $status
        set -l deleted (printf '%s\n' $removals | command jq -r '.[] | select(.branch_outcome == "deleted") | .branch // empty')
        or return $status
        # --foreground waits for removal, but post-remove hooks still run in
        # the background. Finish our idempotent metadata hook before validating.
        for branch in $deleted
            command wt hook post-remove user:stax_untrack --foreground --branch="$branch"
            or return $status
        end
        command stax validate
        or return $status
    else
        command wt step prune --min-age="$min_age" --foreground
        or return $status
    end
end
