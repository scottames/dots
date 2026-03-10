#!/usr/bin/env fish

function zellij_new_tab_edit_split \
    --description "Edit dir/file in new Zellij tab with configurable content split and status layout."

    set -l _argparse_options \
        h/horizontal \
        v/vertical \
        's/suspended=?' \
        'n/name=?' \
        'l/layout=?' \
        'm/status-mode=?' \
        no-status \
        status-vertical \
        status-vertical-right
    argparse -n ze $_argparse_options -- $argv

    set -l _DIR $HOME
    set -l _TAB_NAME "~"
    set -l _NVIM_EXTRA_ARGS ""
    set -l _ARGS ""
    set -l _SPLIT_DIRECTION vertical
    set -l _START_SUSPENDED true
    set -l _STATUS_MODE auto
    set -l _STATUS_SNIPPET_DIR "$HOME/.config/zellij/snippets"
    set -l _LAYOUT_FILE ""

    function __cleanup
        functions -e __cleanup
    end

    if set -q _flag_horizontal
        set _SPLIT_DIRECTION horizontal
    end

    if set -q _flag_suspended
        set _START_SUSPENDED $_flag_suspended
    end

    if set -q _flag_status_mode
        set _STATUS_MODE $_flag_status_mode[1]
    else if set -q _flag_no_status
        set _STATUS_MODE none
    else if set -q _flag_status_vertical
        set _STATUS_MODE vertical
    else if set -q _flag_status_vertical_right
        set _STATUS_MODE vertical-right
    else if set -q ZELLIJ_STATUS_LAYOUT_MODE
        set _STATUS_MODE $ZELLIJ_STATUS_LAYOUT_MODE
    else
        set _STATUS_MODE horizontal
    end

    if test (count $argv) -gt 0
        set _DIR $argv[1]
        set _TAB_NAME (basename $_DIR)
    end

    if test -f $_DIR
        set _NVIM_EXTRA_ARGS " \"$_DIR\""
        set _DIR (path dirname $_DIR)
    else if not test -d $_DIR
        printf_warn "'$_DIR' not exist, assuming edit new file w/ nvim"
        set _NVIM_EXTRA_ARGS " \"$_DIR\""
    end

    if set -q _flag_name
        set _TAB_NAME $_flag_name[1]
    end

    if not set -q _flag_layout
        switch $_STATUS_MODE
            case auto
                set _STATUS_MODE horizontal
            case horizontal vertical vertical-right none
            case '*'
                printf_warn "unknown status mode '$_STATUS_MODE', defaulting to horizontal"
                set _STATUS_MODE horizontal
        end

        if test -n "$_NVIM_EXTRA_ARGS"
            set _ARGS """ {
                  args$_NVIM_EXTRA_ARGS
              }
"""
        end

        set -l _CONTENT_PANE """
          pane split_direction=\"$_SPLIT_DIRECTION\" {
              pane stacked=true {
                pane
                pane
              }
              pane command=\"nvim\"$_ARGS start_suspended=$_START_SUSPENDED
          }
"""

        set -l _STATUS_PANE ""
        set -l _STATUS_SNIPPET_FILE ""
        if test -f "$HOME/.config/zellij/plugins/zellij-status.wasm"
            switch $_STATUS_MODE
                case horizontal
                    set _STATUS_PANE """
          pane size=1 borderless=true {
              plugin location=\"zellij-status\"
          }
"""
                case vertical vertical-right
                    set -l _STATUS_SNIPPET_NAME $_STATUS_MODE
                    if test "$_STATUS_MODE" = vertical
                        set _STATUS_SNIPPET_NAME vertical-left
                    end
                    set _STATUS_SNIPPET_FILE "$_STATUS_SNIPPET_DIR/$_STATUS_SNIPPET_NAME.kdl"

                    if not test -f "$_STATUS_SNIPPET_FILE"
                        printf_warn "missing status snippet '$_STATUS_SNIPPET_FILE', using minimal vertical plugin"
                        set _STATUS_SNIPPET_FILE ""
                        set _STATUS_PANE """
          pane size=26 borderless=true {
              plugin location=\"file:$HOME/.config/zellij/plugins/zellij-status.wasm\" {
                  layout_mode \"vertical\"
              }
          }
"""
                    end
            end
        end

        switch $_STATUS_MODE
            case vertical
                if test -n "$_STATUS_SNIPPET_FILE"
                    set _LAYOUT_FILE (mktemp)
                    begin
                        printf "%s\n" "layout {"
                        printf "%s\n" "    tab {"
                        printf "%s\n" "        pane split_direction=\"vertical\" {"
                        command cat "$_STATUS_SNIPPET_FILE"
                        printf "%s\n" "$_CONTENT_PANE"
                        printf "%s\n" "        }"
                        printf "%s\n" "    }"
                        printf "%s\n" "}"
                    end >"$_LAYOUT_FILE"
                else
                    set _LAYOUT_CONTENT """
  layout {
      tab {
          pane split_direction=\"vertical\" {
              $_STATUS_PANE
              $_CONTENT_PANE
          }
      }
  }
"""
                end
            case vertical-right
                if test -n "$_STATUS_SNIPPET_FILE"
                    set _LAYOUT_FILE (mktemp)
                    begin
                        printf "%s\n" "layout {"
                        printf "%s\n" "    tab {"
                        printf "%s\n" "        pane split_direction=\"vertical\" {"
                        printf "%s\n" "$_CONTENT_PANE"
                        command cat "$_STATUS_SNIPPET_FILE"
                        printf "%s\n" "        }"
                        printf "%s\n" "    }"
                        printf "%s\n" "}"
                    end >"$_LAYOUT_FILE"
                else
                    set _LAYOUT_CONTENT """
  layout {
      tab {
          pane split_direction=\"vertical\" {
              $_CONTENT_PANE
              $_STATUS_PANE
          }
      }
  }
"""
                end
            case none
                set _LAYOUT_CONTENT """
  layout {
      tab {
          $_CONTENT_PANE
      }
  }
"""
            case '*'
                set _LAYOUT_CONTENT """
  layout {
      tab {
          $_CONTENT_PANE
          $_STATUS_PANE
      }
  }
"""
        end

        if test -z "$_LAYOUT_FILE"
            set _LAYOUT_FILE (mktemp)
            printf "%s" "$_LAYOUT_CONTENT" >"$_LAYOUT_FILE"
        end

        function __cleanup
            command rm -- "$argv"
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
