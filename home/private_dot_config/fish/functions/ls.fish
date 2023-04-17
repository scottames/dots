#!/bin/env fish

function ls --wraps exa
  if [ $HAS_EXA ]
    exa --classify --group-directories-first $argv
  else
    command ls $argv
  end
end
