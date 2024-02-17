#!/bin/env fish

function _arg_req_gt_one --description "Tests if at least one arguments provided"
    if test (count $argv) -lt 1
        printf_err "At least one argument required. Got: $argv\n"
        return 1
    end
end
