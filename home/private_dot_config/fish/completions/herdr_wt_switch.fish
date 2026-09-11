function __herdr_wt_switch_worktree_candidates
    # Keep branch and base suggestions aligned with Worktrunk.
    test -n "$WORKTRUNK_BIN"
    or set -l WORKTRUNK_BIN (type -P wt)
    COMPLETE=fish $WORKTRUNK_BIN -- wt switch --no-cd ''
end

complete -c herdr_wt_switch -f
complete -c herdr_wt_switch -s c -l create -d 'Create a new branch'
complete -c herdr_wt_switch -s b -l base -r -f \
    -a '(__herdr_wt_switch_worktree_candidates)' \
    -d 'Base branch'
complete -c herdr_wt_switch -s h -l help -d 'Show usage'
complete -c herdr_wt_switch \
    -n '__fish_is_nth_token 1; and not __fish_seen_argument -s c -l create' \
    -a '(__herdr_wt_switch_worktree_candidates)' \
    -d 'Existing worktree'
