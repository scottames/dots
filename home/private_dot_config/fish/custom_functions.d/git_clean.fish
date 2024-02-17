#!/bin/env fish

function git_clean --description "Checkout the default branch, pull & prune"
    if test (count $argv) -gt 0
        set _branch $argv[1]
    else
        set _branch (git_head_branch)
    end

    git_checkout_pull $_branch \
        && git_prune
end
