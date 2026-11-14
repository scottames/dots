function _stax_primary_worktree
    # Stax JSON status fails on the .bare administrative entry (0.118–0.120).
    # Git's first porcelain entry is the primary checkout or bare repository.
    set -l entries (command git worktree list --porcelain)
    or return $status
    set -l primary (string replace -r '^worktree ' '' -- "$entries[1]")
    if test (command git -C "$primary" rev-parse --is-bare-repository) = true
        set -l trunk (_stax_trunk)
        or return 1
        set primary
        set -l checkout
        for entry in $entries
            if string match -q 'worktree *' -- "$entry"
                set checkout (string replace 'worktree ' '' -- "$entry")
            else if test "$entry" = "branch refs/heads/$trunk"
                set primary "$checkout"
                break
            end
        end
    end
    test -n "$primary"; or return 1
    printf '%s\n' "$primary"
end
