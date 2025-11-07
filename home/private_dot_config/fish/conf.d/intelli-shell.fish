#!/bin/env fish

if status --is-interactive
    and type -q intelli-shell

    ## binds
    set -gx INTELLI_SEARCH_HOTKEY ctrl-space # default: ctrl+space
    ## binds
    set -x INTELLI_BOOKMARK_HOTKEY ctrl-b # default: ctrl+b
    set -x INTELLI_VARIABLE_HOTKEY ctrl-v # default: ctrl+l
    set -x INTELLI_FIX_HOTKEY ctrl-f # default: ctrl-x
    ## Prevents IntelliShell from binding the esc
    ##  key to clear the current line in the terminal.
    # set -x INTELLI_SKIP_ESC_BIND 1 # default: 0

    intelli-shell init fish | source

    # also apply to insert mode... (init only does default)
    bind -M insert $INTELLI_SEARCH_HOTKEY _intelli_search
    bind -M insert $INTELLI_BOOKMARK_HOTKEY _intelli_save
    bind -M insert $INTELLI_VARIABLE_HOTKEY _intelli_replace
    bind -M insert $INTELLI_FIX_HOTKEY _intelli_fix
end
