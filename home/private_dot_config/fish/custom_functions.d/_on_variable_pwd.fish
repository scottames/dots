#!/bin/env fish

function _on_variable_pwd --on-variable PWD \
    --description "Runs when PWD changes"

    # If zellij is not running this is a no-op
    if set -q ZELLIJ
        zellij_rename_tab
    end
end
