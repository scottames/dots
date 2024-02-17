#!/bin/env fish

function _arg_req_one --description "Tests if exactly one argument provided"
    if test (count $argv) -ne 1
        printf_err "Exactly one argument required. Got: $argv\n"
        return 1
    end
end
