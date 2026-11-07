#!/usr/bin/env fish

function herdr_new_workspace \
    --description "Open a Herdr workspace using the current runtime and project naming."

    argparse -n herdr_new_workspace 'l/label=' 's/simple' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        printf 'Usage: herdr_new_workspace [--label NAME] [--simple] [PATH]\n'
        return 0
    end
    if test (count $argv) -gt 1
        printf 'Usage: herdr_new_workspace [--label NAME] [--simple] [PATH]\n' >&2
        return 1
    end

    set -l target .
    if set -q argv[1]
        set target $argv[1]
    end

    if not test -e "$target"
        printf 'herdr_new_workspace: path not found: %s\n' "$target" >&2
        return 1
    end

    set -l cwd "$target"
    if test -f "$cwd"
        set cwd (path dirname "$cwd")
    end
    set cwd (path resolve "$cwd")

    set -l label
    if set -q _flag_label
        set label $_flag_label
    else if set -q HC_TERMINAL_ID
        set label (project_label "$cwd")
        or return 1
    else
        set label (zellij_tab_name "$target")
    end

    if set -q HC_TERMINAL_ID
        set -l rename
        set -q _flag_label; and set rename rename
        _herdr_app_open_space "$cwd" "$label" $rename
        return $status
    end

    if set -q _flag_simple
        command herdr workspace create --cwd "$cwd" --label "$label" --focus >/dev/null
        return
    end

    set -l workspace_result (command herdr workspace create --cwd "$cwd" --label "$label" --focus)
    or return 1

    set -l workspace_id (_herdr_response_id workspace_id "$workspace_result")
    or return 1

    set -l tab_id (_herdr_response_id tab_id "$workspace_result")
    or return 1

    set -l pane_id (_herdr_response_id pane_id "$workspace_result")
    or return 1

    herdr_layout_default \
        --workspace "$workspace_id" \
        --tab "$tab_id" \
        --pane "$pane_id" \
        --cwd "$cwd"
end
