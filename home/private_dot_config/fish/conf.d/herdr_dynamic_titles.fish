#!/usr/bin/env fish

function __herdr_dynamic_title_preexec \
    --on-event fish_preexec \
    --description "Report the running fish command to Herdr pane metadata."

    if not set -q HERDR_ENV
        return 0
    end

    set -l context (_herdr_current_pane_context)
    or return 0

    set -l context_parts (string split \t -- "$context")
    if test (count $context_parts) -ne 4
        return 0
    end

    set -l pane_id "$context_parts[1]"
    set -l tab_id "$context_parts[2]"
    set -l is_first_pane "$context_parts[4]"

    set -g __herdr_dynamic_title_pane_id "$pane_id"
    set -g __herdr_dynamic_title_tab_id "$tab_id"
    set -g __herdr_dynamic_title_is_first_pane "$is_first_pane"

    set -l label (_herdr_command_label (string join ' ' -- $argv))

    command herdr pane report-metadata "$pane_id" \
        --source fish-command \
        --title "$label" \
        --ttl-ms 300000 >/dev/null 2>&1

    if test "$is_first_pane" = 1
        if not set -q __herdr_dynamic_title_restore_label
            set -g __herdr_dynamic_title_restore_label shell
            if set -q SHELL
                set -g __herdr_dynamic_title_restore_label (_herdr_command_label (string join ' ' --  (path basename -- "$SHELL")))
            end
        end

        command herdr tab rename "$tab_id" "$label" >/dev/null 2>&1
    end
end

function __herdr_dynamic_title_postexec \
    --on-event fish_postexec \
    --description "Clear Herdr fish command metadata after command completion."

    if not set -q HERDR_ENV __herdr_dynamic_title_pane_id
        return 0
    end

    command herdr pane report-metadata "$__herdr_dynamic_title_pane_id" \
        --source fish-command \
        --clear-title >/dev/null 2>&1

    if set -q __herdr_dynamic_title_tab_id __herdr_dynamic_title_is_first_pane
        and test "$__herdr_dynamic_title_is_first_pane" = 1
        command herdr tab rename "$__herdr_dynamic_title_tab_id" "$__herdr_dynamic_title_restore_label" >/dev/null 2>&1
    end

    set -e __herdr_dynamic_title_pane_id \
        __herdr_dynamic_title_tab_id \
        __herdr_dynamic_title_is_first_pane
end
