#!/bin/env fish

function zellij_attach --description "Attach to existing Zellij session(s) - if not provided, fzf is used to pick"
    if test (count $argv) -ge 1
        zellij attach $argv
    end

    set -l sessions (zellij list-sessions)
    set -l session_count (count $sessions)

    if [ $session_count -ge 2 ]
        zellij attach (
             printf %s\n $sessions \
             | ugum filter --header="choose a session to attach to..." --placeholder="" \
             | string split ' ' -f1
        )
    else
        zellij attach -c # creates a session if one does not exist
    end
end
