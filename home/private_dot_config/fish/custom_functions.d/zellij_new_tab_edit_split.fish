#!/usr/bin/env fish

function zellij_new_tab_edit_split \
    --description "Edit dir/file in new Zellij tab. Defaults to horizonal layout, can specify --vertical."

    set -l _argparse_options h/horizontal v/vertical 'n/name=?'
    argparse -n ze $_argparse_options -- $argv

    set -l _DIR $HOME
    set -l _TAB_NAME "~"
    set -l _NVIM_EXTRA_ARGS ""
    set -l _ARGS ""
    set -l _SPLIT_DIRECTION horizontal

    if set -q _flag_vertical
        set _SPLIT_DIRECTION vertical
    end

    if test (count $argv) -gt 0
        set _DIR $argv[1]
        set _TAB_NAME (basename $_DIR)
    end

    if test -f $_DIR
        set _NVIM_EXTRA_ARGS " \"$_DIR\""
        set _DIR (path dirname $_DIR)
    else if ! test -d $_DIR
        print_warn "'$_DIR' not exist, assuming edit new file w/ nvim"
        set _NVIM_EXTRA_ARGS " \"$_DIR\""
    end

    if set -q _flag_name
        set _TAB_NAME $_flag_name[1]
    end

    printf "_TAB_NAME: "
    set --show _TAB_NAME
    printf "_flag_name: "
    set --show _flag_name

    if [ $_NVIM_EXTRA_ARGS ]
        set _ARGS """ {
                  args $_NVIM_EXTRA_ARGS
              }
"""
    end

    set _LAYOUT_CONTENT """
  layout {
      tab name=\"$_TAB_NAME\" {
          pane split_direction=\"$_SPLIT_DIRECTION\" {
              pane command=\"nvim\"$_ARGS
              pane
          }
          pane size=1 borderless=true {
              plugin location=\"zellij:compact-bar\"
          }
      }
  }
  """

    set -l _LAYOUT_FILE (mktemp)
    printf $_LAYOUT_CONTENT >"$_LAYOUT_FILE"

    if set -q _DIR
        zellij action new-tab -c $_DIR --layout "$_LAYOUT_FILE"
    else
        zellij action new-tab -c $HOME --layout "$_LAYOUT_FILE"
    end
    rm "$_LAYOUT_FILE"
end
