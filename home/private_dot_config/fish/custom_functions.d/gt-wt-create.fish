#!/usr/bin/env fish

# Graphite-only bridge: create a plain branch first so Stax does not track it.
function gt-wt-create
    argparse --min-args=1 --max-args=1 b/base= no-cd -- $argv
    or return 2
    set -l base $_flag_base
    if not set -q _flag_base
        set base (_stax_trunk)
        or return 1
    end
    command git branch "$argv[1]" "$base"
    or return 1
    set -l destination (_stax_worktree_path --create --base "$base" "$argv[1]")
    or return 1
    # Track in a child shell, leaving the caller's checkout and cwd untouched.
    command fish --no-config -c 'cd "$argv[1]"; and command gt track --parent "$argv[2]"' -- "$destination" "$base"
    or return 1
    if not set -q _flag_no_cd
        cd "$destination"
    end
end
