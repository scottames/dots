#!/bin/env fish

function ls --wraps exa
  if [ $HAS_EXA ]
    exa --classify --group-directories-first $argv
  else
    printf_warn "exa not found, defaulting to builtin ls\n\n"
    ls $argv
  end
end
