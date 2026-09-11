#!/bin/env fish

function plannotator-tui --wraps plannotator-tui --description "Use the Annotate plugin for Herdr reviews"
    if test "$argv[1]" = herdr
        HERDR_PLUGIN_ID=annotate command plannotator-tui $argv
    else
        command plannotator-tui $argv
    end
end
