#!/usr/bin/env fish

function zellij_new_tab_edit_split \
    --description "Edit dir/file in new Zellij tab. Defaults to horizontal layout, can specify --vertical."

    set -l _argparse_options h/horizontal v/vertical 's/suspended=?' 'n/name=?' 'l/layout=?'
    argparse -n ze $_argparse_options -- $argv

    set -l _DIR $HOME
    set -l _TAB_NAME "~"
    set -l _NVIM_EXTRA_ARGS ""
    set -l _ARGS ""
    set -l _SPLIT_DIRECTION vertical
    set -l _START_SUSPENDED true
    set _LAYOUT_FILE ""

    function __cleanup
        functions -e __cleanup
    end

    if set -q _flag_horizontal
        set _SPLIT_DIRECTION horizontal
    end

    if set -q _flag_suspended
        set _START_SUSPENDED $_flag_suspended
    end

    if test (count $argv) -gt 0
        set _DIR $argv[1]
        set _TAB_NAME (basename $_DIR)
    end

    if test -f $_DIR
        set _NVIM_EXTRA_ARGS " \"$_DIR\""
        set _DIR (path dirname $_DIR)
    else if ! test -d $_DIR
        printf_warn "'$_DIR' not exist, assuming edit new file w/ nvim"
        set _NVIM_EXTRA_ARGS " \"$_DIR\""
    end

    if set -q _flag_name
        set _TAB_NAME $_flag_name[1]
    end

    if not set -q _flag_layout

        if [ $_NVIM_EXTRA_ARGS ]
            set _ARGS """ {
                  args $_NVIM_EXTRA_ARGS
              }
"""
        end

        set _LAYOUT_CONTENT """
  layout {
      tab {
          pane split_direction=\"$_SPLIT_DIRECTION\" {
              pane command=\"nvim\"$_ARGS start_suspended=$_START_SUSPENDED
              pane stacked=true {
                pane
                pane
              }
          }
          pane size=1 borderless=true {
              plugin location=\"zjstatus\"
          }
      }
  }
  """

        set _LAYOUT_FILE (mktemp)
        printf $_LAYOUT_CONTENT >"$_LAYOUT_FILE"

        function __cleanup
            rm "$argv"
            functions -e __cleanup
        end
    else
        set _LAYOUT_FILE $_flag_layout
    end

    if set -q _DIR
        zellij action new-tab -c $_DIR --layout "$_LAYOUT_FILE" --name $_TAB_NAME
    else
        zellij action new-tab -c $HOME --layout "$_LAYOUT_FILE" --name $_TAB_NAME
    end

    __cleanup $_LAYOUT_FILE

end
