#!/usr/bin/env fish

function zellij_tab_name --description "Print a stable Zellij tab name for a path"
    if set -q argv[1]
        project_label --separator=. "$argv[1]"
    else
        project_label --separator=.
    end
end
