#!/usr/bin/env fish

function git_prune --description "Preview eligible checkout cleanup; --apply to remove"
    argparse --max-args=0 apply h/help -- $argv
    or return 2
    if set -q _flag_help
        printf '%s\n' \
            'Usage: git_prune [--apply]' \
            'Remove clean, inactive, ancestry-merged checkouts older than two days.' \
            'Branches/metadata are retained; parents, uncertain activity and squash merges are skipped.' \
            '--apply requires the clean primary checkout on trunk and pulls --ff-only.' \
            'Stale bookkeeping is also pruned, with a minimum age of two days.' \
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
    set -l options
    set -q _flag_apply; and set options --apply
    # Resolve relative to this deployed function, also supporting source-tree tests.
    set -l helper (path resolve (path dirname (status filename))/../../stax/prune-worktrees.py)
    command python3 "$helper" --primary "$primary" --trunk "$trunk" $options
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
        printf '\nStale worktree bookkeeping\n'
        command stax worktree prune
        or return $status
        # Keep the post-cleanup check, but only repeat its details on failure.
        set -l validation (command stax validate 2>&1)
        set -l validation_status $status
        if test $validation_status -ne 0
            printf '%s\n' $validation >&2
            return $validation_status
        end
        printf '\nCleanup complete. Stack validation passed.\nBranches and stack metadata retained.\n'
    else
        set -l bookkeeping (command git worktree prune --dry-run --verbose --expire=2.days.ago)
        or return $status
        if test (count $bookkeeping) -gt 0
            printf '\nWould prune stale bookkeeping\n'
            printf '  - %s\n' $bookkeeping
        end
        printf '\nNo changes were made. Run git_prune --apply from %s on %s to apply cleanup.\n' "$primary" "$trunk"
        printf 'Branches and stack metadata will be retained.\n'
    end
end
