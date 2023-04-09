#!/bin/env fish

function op_signin
  if ! [ $HAS_OP ]
    print_err "op not found"
    return 1
  end
  if set -q argv[1]
    set OP_TEAM $argv[1]
  else
    set OP_TEAM my
  end

  eval (op signin --account "$OP_TEAM.1password.com")
end
