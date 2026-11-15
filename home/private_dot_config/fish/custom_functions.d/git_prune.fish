#!/usr/bin/env fish

function git_prune --description "Preview cleanup; --apply prunes stale bookkeeping only"
    argparse --max-args=0 apply h/help -- $argv
    or return 2
    if set -q _flag_help
        printf '%s\n' \
            'Usage: git_prune [--apply]' \
            'Live worktrees and branches are always retained (including old, merged ones).' \
            'Stax lacks the old two-day/activity guard; bulk live deletion is disabled.' \
            '--apply requires the clean primary checkout on trunk and pulls --ff-only.' \
            'Only stale Git worktree bookkeeping is pruned, with a minimum age of two days.' \
            'Review individual removals with stax worktree rm; keep branches with children.'
        return 0
    end
    set -l trunk (_stax_trunk)
    or return 1
    set -l primary (_stax_primary_worktree)
    or return 1
    if set -q _flag_apply
        if test (command git rev-parse --show-toplevel) != "$primary"; or test (command git branch --show-current) != "$trunk"
            printf 'git_prune: run --apply from %s on branch %s.\n' "$primary" "$trunk" >&2
            return 1
        end
        set -l changes (command git status --porcelain)
        or return 1
        if test (count $changes) -gt 0
            printf 'git_prune: the primary worktree must be clean.\n' >&2
            return 1
        end
    end
    # Validate before any mutation; never repair metadata implicitly.
    if command git show-ref --verify --quiet refs/stax/trunk
        command stax validate
        or return $status
    end
    if set -q _flag_apply
        command git pull --ff-only
        or return $status
    end
    printf 'Live worktrees and branches retained: Stax has no age/activity guard.\n'
    command stax worktree list
    or return $status
    # Stax prune has no expiry argument. Gate the entire native prune: one young
    # or uncertain missing entry keeps all bookkeeping until the next run.
    if set -q _flag_apply
        # Missing directories can still have recoverable staged data or an
        # interrupted operation. Refuse pruning rather than losing that state.
        set -l common (command git rev-parse --path-format=absolute --git-common-dir)
        for admin in "$common"/worktrees/*
            test -d "$admin"; or continue
            set -l gitfile (string trim <"$admin/gitdir")
            test -e "$gitfile"; and continue
            if not command python3 -c 'import os, sys, time; sys.exit(time.time() - os.stat(sys.argv[1]).st_mtime < 172800)' "$admin/gitdir"
                printf 'Retaining all stale entries: %s is younger than two days or has unknown age.\n' "$admin"
                return 0
            end
            for marker in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD
                if test -e "$admin/$marker"
                    printf 'git_prune: recover interrupted worktree %s before pruning.\n' "$admin" >&2
                    return 1
                end
            end
            command git --git-dir="$admin" diff --cached --quiet HEAD --
            or begin
                printf 'git_prune: recover staged/unknown state in %s before pruning.\n' "$admin" >&2
                return 1
            end
        end
        command stax worktree prune
        or return $status
        command stax validate
    else
        command git worktree prune --dry-run --verbose --expire=2.days.ago
    end
end
