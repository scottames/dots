#!/bin/env fish

function mage \
    --description "wraps mage, if no argument provided fzf searches mage targets and executes selected" \
    --wraps mage

    if test (count $argv) -eq 0
        # sed strips color characters (if enabled)
        set _cmd ( command mage -l \
               | tail -n +2 \
               | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" \
               | fzf \
               | awk '{print $1}')
        if set -q _cmd[1]
            command mage $_cmd
        end
    else
        command mage $argv
    end
end
