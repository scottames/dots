#!/bin/env fish

function up --description "cd up N (default: 1) directories"
  set -l num
  if set -q argv[1]
    set num $argv[1]
  else
    set num 1
  end
  if not string match -qr '^-?[0-9]+(\.?[0-9]*)?$' -- $num
    printf_err "argument must be positive integer"
    return 1
  end

  for i in (seq $num)
    cd ../
  end
end
