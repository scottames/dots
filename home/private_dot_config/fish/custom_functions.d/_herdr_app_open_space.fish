#!/usr/bin/env fish

function _herdr_app_open_space --description "Open or select a local desktop space (folder, label, optional rename)"
    set -l cwd "$argv[1]"
    set -l checkout (command git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    set -l label "$argv[2]"

    set -l spaces (command herdr-app ls)
    or return 1
    set -l candidates (printf '%s\n' "$spaces" | command jq -r '
        .spaces[] | select(.machine == null) | . as $space |
        .tabs[].terminals[] | [$space.id, .terminal] | @tsv')
    or return 1
    for candidate in $candidates
        set -l fields (string split \t -- "$candidate")
        set -l terminal (command hc get "$fields[2]")
        or return 1
        # ls JSON keeps the launch folder; get also exposes the live foreground folder.
        set -l folder (printf '%s\n' "$terminal" | command jq -r '.foreground.cwd // .cwd // empty')
        or return 1
        test -n "$folder"; or continue
        set folder (path resolve "$folder")
        if test -n "$checkout"
            set -l root (command git -C "$folder" rev-parse --show-toplevel 2>/dev/null)
            test "$root" = "$checkout"; or continue
        else
            test "$folder" = "$cwd"; or continue
        end
        # Preserve names on reused spaces unless a label was explicitly requested.
        if contains -- rename $argv[3..-1]
            command herdr-app do space.rename --id "$fields[1]" --name "$label" >/dev/null
            or return 1
        end
        command herdr-app do space.select --id "$fields[1]" >/dev/null
        return $status
    end

    command herdr-app do space.new --folder "$cwd" --name "$label" >/dev/null
end
