#!/usr/bin/env fish

function zellij_new_tab_edit_split
    _arg_req_one $argv || return 1

    set -l _DIR $argv[1]
    set -l _LAYOUT_FILE (mktemp)

    set _LAYOUT_CONTENT """
  layout {
      pane split_direction=\"horizontal\" {
          pane command=\"nvim\" {
              args \"$_DIR\"
          }
          pane
      }
      pane size=1 borderless=true {
          plugin location=\"zellij:compact-bar\"
      }
  }
  """

    printf $_LAYOUT_CONTENT >"$_LAYOUT_FILE"
    trap "rm '$_LAYOUT_FILE'" EXIT

    zellij action new-tab -c "$_DIR" --layout "$_LAYOUT_FILE"
end
