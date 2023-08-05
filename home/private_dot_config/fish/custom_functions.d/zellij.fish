#!/bin/env fish

function zellij \
  --description "Wraps zellij enabling catppuccin-latte theme during daylight hours"

  set -l h (date +%k)
  if test $h -gt 5
    and test $h -lt 19
    command zellij $argv options --theme catppuccin-latte
  end

  command zellij $argv
end
