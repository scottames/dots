#!/bin/env fish

function em --description "Edit in new multiplexer pane, closes on exit" --wraps $EDITOR
    if set -q ZELLIJ
        zellij edit $argv
    else if set -q TMUX
        tmux split-window $EDITOR $argv
    end
end
