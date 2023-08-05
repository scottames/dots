#!/bin/env fish

function is_light --description "returns true if it is light (day) time"

  set -l h (date +%k)
  if test $h -lt 6
    or test $h -gt 18
    printf false
    return 1
  end

  printf true
  return 0
end
