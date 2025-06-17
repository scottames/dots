#!/bin/env fish

function eval_abbr --description "eval an abbr"
    set -l abbr_name $argv[1]
    set -l expansion (
      abbr --show \
      | grep "abbr -a -- $abbr_name " \
      | cut -d\' -f2
    )
    eval "$expansion"
end
