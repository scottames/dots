#!/bin/env fish

function getclip --wraps xclip
  if [ $HAS_XCLIP ]
    xclip -selection c -o $argv
  end
end
