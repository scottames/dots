#!/bin/env fish

function setclip --description "Set to clipboard"
  if [ $HAS_XCLIP ]
    xclip -selection c $argv
  else if [ $IS_MAC ]
    pbcopy $argv
  end
end
