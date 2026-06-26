#!/usr/bin/env fish

function herdr_tab_git \
    --description "Open a git tools tab in the current Herdr workspace."

    set -l context (_herdr_current_pane_context)
    or begin
        printf 'herdr_tab_git: must be run inside a focused Herdr pane\n' >&2
        return 1
    end

    set -l fields (string split (printf '\t') -- "$context")
    set -l current_pane_id $fields[1]
    set -l workspace_id $fields[3]

    set -l pane_json (command herdr pane get "$current_pane_id")
    or return 1

    set -l cwd (printf '%s\n' "$pane_json" | command jq -r '.result.pane.cwd // .result.pane.foreground_cwd // empty')
    or return 1

    if test -z "$cwd"
        printf 'herdr_tab_git: could not resolve current pane cwd\n' >&2
        return 1
    end

    set -l tab_result (command herdr tab create \
        --workspace "$workspace_id" \
        --cwd "$cwd" \
        --focus)
    or return 1

    set -l tab_id (_herdr_response_id tab_id "$tab_result")
    or return 1

    set -l top_pane_id (_herdr_response_id pane_id "$tab_result")
    or return 1

    set -l bottom_result (command herdr pane split "$top_pane_id" \
        --direction down \
        --ratio 0.80 \
        --cwd "$cwd" \
        --no-focus)
    or return 1

    set -l bottom_left_pane_id (_herdr_response_id pane_id "$bottom_result")
    or return 1

    set -l bottom_right_result (command herdr pane split "$bottom_left_pane_id" \
        --direction right \
        --ratio 0.40 \
        --cwd "$cwd" \
        --no-focus)
    or return 1

    set -l bottom_right_pane_id (_herdr_response_id pane_id "$bottom_right_result")
    or return 1

    sleep 0.5

    command herdr pane run "$top_pane_id" 'lazygit'
    or return 1

    command herdr pane run "$bottom_left_pane_id" 'GIT_PAGER=cat PAGER=cat BAT_PAGER=cat git --no-pager stack-watch'
    or return 1

    command herdr pane run "$bottom_right_pane_id" 'wt pane-watch'
    or return 1

    sleep 1
    command herdr tab rename "$tab_id" git >/dev/null
    or return 1

    command herdr tab focus "$tab_id" >/dev/null
end
