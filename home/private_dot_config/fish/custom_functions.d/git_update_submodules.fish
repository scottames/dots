#!/bin/env fish

function git_update_submodules \
    --description "Update all git submodules to latest"
    if test (count $argv) -gt 0
        set _branch $argv[1]
    else
        set _branch (git_head_branch)
    end

    git submodule sync
    git submodule init
    git submodule update
    git submodule foreach \
        "(git checkout $_branch && git pull --ff origin $_branch && git push origin $_branch) || true"

    for i in (git submodule foreach --quiet 'echo $path')
        echo "Add $i"
        git add "$i"
    end
end
