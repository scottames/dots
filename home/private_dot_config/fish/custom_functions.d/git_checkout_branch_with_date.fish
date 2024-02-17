#!/bin/env fish

function git_checkout_branch_with_date \
    --description "git checkout new branch w/ initials + date appended to the name"

    _arg_req_one $argv || return 1

    set _branch_name "sa-$(date "+%Y-%m-%d")-$argv[1]"
    git checkout -b $_branch_name
end
