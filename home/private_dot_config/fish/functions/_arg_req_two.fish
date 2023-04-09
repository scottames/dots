#!/bin/env fish

function _arg_req_two --description "Tests if exactly two arguments provided"
  if test (count $argv) -ne 2
    printf_err "Exactly two argument required. Got: $argv\n"
    return 1
  end
end
