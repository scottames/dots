# Resolve/create through Stax without changing the calling shell's directory.
function _stax_worktree_path
    argparse --max-args=1 c/create b/base= -- $argv
    or return 2
    set -l action go
    set -l options
    if set -q _flag_create
        set action create
        set -l base $_flag_base
        if not set -q _flag_base
            set base (_stax_trunk)
            or return 1
        else if test "$base" = @
            set base (command git branch --show-current)
        end
        test -n "$base"; or return 1
        set options --from "$base"
    else if set -q _flag_base
        printf 'Use --base with --create.\n' >&2
        return 2
    end
    # In .bare layouts Stax calls the admin directory "main", making the main
    # branch ambiguous. An exact checked-out branch can be passed by its path.
    if set -q argv[1]
        set -l checkout
        for entry in (command git worktree list --porcelain)
            if string match -q 'worktree *' -- "$entry"
                set checkout (string replace 'worktree ' '' -- "$entry")
            else if test "$entry" = "branch refs/heads/$argv[1]"
                set argv[1] "$checkout"
                break
            end
        end
    end
    # The native Fish integration uses this same payload. Picker UI goes to tty.
    # Do not eval output: setup hooks can also write to stdout.
    set -l result (command stax worktree $action $argv $options --shell-output)
    or begin
        set -l failure $status
        printf '%s\n' $result >&2
        return $failure
    end
    set -l destination (string match --regex '^STAX_SHELL_PATH=.*' -- $result | string replace 'STAX_SHELL_PATH=' '')
    test -n "$destination"; or return 0
    if test (command git -C "$destination" rev-parse --is-bare-repository) = true
        printf 'Select a checkout, not the bare administrative directory.\n' >&2
        return 1
    end
    printf '%s\n' "$destination"
end
