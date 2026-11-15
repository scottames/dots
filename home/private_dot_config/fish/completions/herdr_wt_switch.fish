complete -c herdr_wt_switch -f
complete -c herdr_wt_switch -s c -l create -d 'Create a Stax worktree from trunk'
complete -c herdr_wt_switch -s b -l base -r -a '(git for-each-ref --format="%(refname:short)" refs/heads)' -d 'Explicit base branch (@ for current)'
complete -c herdr_wt_switch -s h -l help -d 'Show usage'
complete -c herdr_wt_switch -a '(git worktree list --porcelain | string match -r "^branch refs/heads/.*" | string replace "branch refs/heads/" "")' -d 'Existing worktree'
