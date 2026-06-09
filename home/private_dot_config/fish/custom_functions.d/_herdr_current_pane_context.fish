#!/usr/bin/env fish

function _herdr_current_pane_context \
    --description "Print the focused Herdr pane context for this shell."

    if not set -q HERDR_ENV
        return 1
    end

    if not type -q herdr; or not type -q jq
        return 1
    end

    set -l panes_json (command herdr pane list 2>/dev/null)
    or return 1

    set -l context (printf '%s\n' "$panes_json" | command jq -r '
        .result.panes as $panes
        | ($panes | map(select(.focused == true))) as $focused
        | if ($focused | length) == 1 then
            $focused[0] as $pane
            | ($panes | map(select(.tab_id == $pane.tab_id)) | .[0].pane_id) as $first_pane
            | [
                $pane.pane_id,
                $pane.tab_id,
                $pane.workspace_id,
                (if $pane.pane_id == $first_pane then "1" else "0" end)
              ]
            | @tsv
          else
            empty
          end
    ')
    or return 1

    if test -z "$context"
        return 1
    end

    printf '%s\n' "$context"
end
