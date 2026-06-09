#!/usr/bin/env fish

function herdr_layout_default \
    --description "Apply the default Herdr workspace layout to an existing workspace."

    argparse -n herdr_layout_default \
        'w/workspace=' \
        't/tab=' \
        'p/pane=' \
        'c/cwd=' \
        -- $argv
    or return 1

    for flag in workspace tab pane cwd
        set -l flag_name _flag_$flag
        if not set -q $flag_name
            printf 'herdr_layout_default: --%s is required\n' "$flag" >&2
            return 1
        end
    end

    set -l cwd $_flag_cwd
    if not test -e "$cwd"
        printf 'herdr_layout_default: path not found: %s\n' "$cwd" >&2
        return 1
    end

    if test -f "$cwd"
        set cwd (path dirname "$cwd")
    end
    set cwd (path resolve "$cwd")

    set -l right_pane_result (command herdr pane split $_flag_pane \
        --direction right \
        --cwd "$cwd" \
        --no-focus)
    or return 1

    set -l right_pane_id (_herdr_response_id pane_id "$right_pane_result")
    or return 1

    command herdr pane split "$right_pane_id" \
        --direction down \
        --cwd "$cwd" \
        --no-focus >/dev/null
    or return 1

    command herdr tab create \
        --workspace $_flag_workspace \
        --cwd "$cwd" \
        --no-focus >/dev/null
    or return 1

    command herdr tab focus $_flag_tab >/dev/null
end
