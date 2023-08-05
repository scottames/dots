#!/bin/env fish

function zellij \
  --description "Wraps zellij enabling catppuccin-latte theme during daylight hours"

  if is_light > /dev/null
    command zellij $argv options --theme catppuccin-latte
  end

  command zellij $argv
end
