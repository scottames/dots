#!/bin/env fish

function cat --wraps bat --description "alias cat to bat"
  if $HAS_BAT
    bat $argv
  else
    printf_warn "'bat' not found - defaulting to cat\n"
    cat $argv
  end
end
