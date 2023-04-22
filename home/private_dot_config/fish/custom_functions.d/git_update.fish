#!/bin/env fish

function git_update --description "Pull & rebase base branch (1) default: head branch"
    if test (count $argv) -gt 0
      set _branch $argv[1]
    else
      set _branch (git_head_branch)
    end

    git_checkout_pull $_branch \
    && git checkout - \
    && git rebase $_branch
end
